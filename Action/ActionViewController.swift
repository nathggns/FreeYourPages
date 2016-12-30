//
//  ActionViewController.swift
//  Action
//
//  Created by Nathaniel Higgins on 27/12/2016.
//  Copyright © 2016 Nathaniel Higgins. All rights reserved.
//

import UIKit
import MobileCoreServices
import Alamofire
import PromiseKit
import SwiftyJSON
import KeychainSwift

extension String: Error {}

enum ActionError: Error {
    case tempWritingFailed
    case pathCreationFailed
}

class ActionViewController: UIViewController {
    let baseUrl = "https://www.scribd.com"
    let loginEndpoint = "/login"
    let csrfExpr = "<meta name=\"csrf-token\" content=\"([^\"]+)\" \\/>"
    let bookExpr = "\\/book\\/([\\d]+)"
    let bookEndpoint = "/book/"
    let getPasswordEndpoint = "/read/download_dialog?template=pdfs&id="
    let downloadEndpoint = "/document_downloads/"
    
    var email: String?
    var password: String?
    var scribd: Scribd!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let kc = KeychainSwift()
        kc.accessGroup = Bundle.main.object(forInfoDictionaryKey: "Keychain Group") as! String?
        
        if let email = kc.get("scribdEmail"), let password = kc.get("scribdPassword") {
            self.email = email
            self.password = password
            self.scribd = Scribd(email: email, password: password)
        } else {
            let alert = UIAlertController(title: "Not logged in", message: "You need to login to Scribd in the app first", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
    
        let extensionItem = extensionContext?.inputItems.first as! NSExtensionItem
        let itemProvider = extensionItem.attachments?.first as! NSItemProvider
        
        
        if itemProvider.hasItemConformingToTypeIdentifier(kUTTypePlainText as String) {
            itemProvider.loadItem(forTypeIdentifier: kUTTypePlainText as String) { (item, error) -> Void in
                let text = item as! String
                let urls = self.extractURLs(string: text)
                
                if let url = urls.first {
                    self.initDownload(withURL: url)
                } else {
                    NSLog("Not URL found")
                }
            }
        } else {
            NSLog("Not a string")
        }
    }
    
    func extractURLs(string: String) -> [NSURL] {
        var urls : [NSURL] = []
        
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: string, options: [], range: NSRange(location: 0, length: string.characters.count))
        
        for match in matches {
            let urlString = (string as NSString).substring(with: match.range)
            
            urls.append(NSURL(string: urlString)!)
        }
        
        return urls
    }
    
    func initDownload(withURL url: NSURL) -> Void {
        
        if scribd.isScribdURL(url: url) {
            if let id = scribd.parseDocumentId(url: url) {
                return initDownload(withBookID: id)
            } else {
                NSLog("No document found")
            }
        } else {
            NSLog("Not a valid Scribd URL")
        }
    }
    
    func initDownload(withBookID id: String) {
        _ = firstly { self.scribd.handleLogin() }
            .then { _ in self.scribd.getBookPassword(withBookID: id) }
            .then { password in self.scribd.getDownloadURL(withBookID: id, ext: "pdf", password: password) }
            .then { downloadURL in self.presentRemotePDF(fromURL: downloadURL) }
            .catch { error in
                NSLog(error.localizedDescription)
            }
    }
    
    func presentRemotePDF(fromURL url: URLConvertible) -> Promise<Void> {
        return firstly { generateRandomLocalURL() }
            .then { path in self.writePDF(fromURL: url, to: path) }
            .then { path -> Promise<Void> in self.presentLocalPDF(fromURL: path) }
    }
    
    func presentLocalPDF(fromURL url: URL) -> Promise<Void> {
        let pending = Promise<Void>.pending()
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(vc, animated: true) {
            pending.fulfill()
        }
        
        return pending.promise

    }
    
    func writePDF(fromURL url: URLConvertible, to: URL) -> Promise<URL> {
        return firstly { Alamofire.request(url).responseData() }.then { (data: Data) throws -> URL in
            do {
                try data.write(to: to, options: [.atomic])
                
                return to
            } catch {
                throw ActionError.tempWritingFailed
            }
        }

    }
    
    func generateRandomLocalURL() -> Promise<URL> {
        let pending = Promise<URL>.pending()
        let name = "file" + String(arc4random_uniform(1000000)) + ".pdf"
        let folder = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last
        
        if let path = folder?.appendingPathComponent(name) {
            pending.fulfill(path)
        } else {
            pending.reject(ActionError.tempWritingFailed)
        }
        
        return pending.promise
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func done() {
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}
