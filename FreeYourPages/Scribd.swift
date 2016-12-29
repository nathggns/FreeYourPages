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

enum ScribdError: Error {
    case csrfNotFound
    case docPasswordNotFound
    case loginFailed
}

class Scribd {
    
    
    let baseUrl = "https://www.scribd.com"
    let loginEndpoint = "/login"
    let csrfExpr = "<meta name=\"csrf-token\" content=\"([^\"]+)\" \\/>"
    let bookExpr = "\\/book\\/([\\d]+)"
    let bookEndpoint = "/book/"
    let getPasswordEndpoint = "/read/download_dialog?template=pdfs&id="
    let downloadEndpoint = "/document_downloads/"
    
    var email: String
    var password: String
    
    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    
    func getDownloadURL(withBookID id: String, ext: String, password: String) -> String {
        return baseUrl + downloadEndpoint + id + "?extension=" + ext + "&secret_passsword=" + password
    }
    
    
    func getBookPassword(withBookID id: String) -> Promise<String> {
        return firstly { self.getCsrfToken(fromURL: self.getBookURL(withBookID: id)) }
            .then { csrf in self.getBookPassword(withBookID: id, csrfToken: csrf) }
    }
    
    func getBookPassword(withBookID id: String, csrfToken csrf: String) -> Promise<String> {
        let url = baseUrl + getPasswordEndpoint + id
        
        return firstly { self.post(withCsrf: csrf, url: url, body: [:]).responseJSON() }
            .then { result -> String in
                let json = JSON(result);
                
                if let pass = json["props"]["document"]["secret_password"].string {
                    return pass
                } else {
                    throw ScribdError.docPasswordNotFound
                }
                
        }
    }
    
    func getBookURL(withBookID id: String) -> String {
        return baseUrl + bookEndpoint + id
    }
    
    func parseDocumentId(url: NSURL) -> String? {
        if !isScribdURL(url: url) {
            return nil
        }
        
        let path = url.path!
        let regex = try! NSRegularExpression(pattern: bookExpr, options: [])
        let matches = regex.matches(in: path, options: [], range: NSMakeRange(0, (path as NSString).length))
        
        if let match = matches.first {
            return (path as NSString).substring(with: match.rangeAt(1))
        }
        
        
        return nil
    }
    
    func post(withCsrf csrf: String, url: String, body: [String: String]) -> DataRequest {
        let headers = [
            "X-CSRF-Token": csrf,
            "X-Requested-With": "XMLHttpRequest",
            "X-Tried-CSRF": "1"
        ]
        
        return Alamofire.request(url, method: .post, parameters: body, encoding: URLEncoding.httpBody, headers: headers)
    }
    
    func handleLogin() -> Promise<Void> {
        let loginUrl = baseUrl + loginEndpoint
        let promise = Promise<Void>.pending()
        let body = [
            "login_or_email": email,
            "login_password": password,
            "rememberme": "on"
        ]
        
        _ = firstly { getCsrfToken(fromURL: loginUrl) }
            .then { csrf in self.post(withCsrf: csrf, url: loginUrl, body: body).responseString() }
            .then { str -> Void in
                let json = JSON(data: str.data(using: .utf8)!)
                let success = json["success"]
                
                if let success = success.bool {
                    if success {
                        promise.fulfill()
                    } else {
                        promise.reject(ScribdError.loginFailed)
                    }
                } else {
                    promise.reject(ScribdError.loginFailed)
                }
            }
            .catch { error in
                NSLog(error.localizedDescription)
                promise.reject(ScribdError.loginFailed)
        }
        
        return promise.promise
    }
    
    func getCsrfToken(fromURL: String) -> Promise<String> {
        return firstly { Alamofire.request(fromURL).responseData() }
            .then { data -> String in
                if let token = self.getCsrfToken(fromData: data) {
                    return token
                }
                
                throw ScribdError.csrfNotFound
        }
    }
    
    
    func getCsrfToken(fromData: Data) -> String? {
        let html = String(data: fromData, encoding: String.Encoding.utf8)!
        let regex = try! NSRegularExpression(pattern: csrfExpr, options: [])
        let matches = regex.matches(in: html, options: [], range: NSMakeRange(0, (html as NSString).length))
        
        if let match = matches.first {
            return (html as NSString).substring(with: match.rangeAt(1))
        }
        
        return nil
    }
    
    func isScribdURL(url: NSURL) -> Bool {
        let urlString = (url.absoluteString! as NSString)
        let length = baseUrl.characters.count
        let match = urlString.substring(with: NSRange(location: 0, length: length)) as String
        
        return match == baseUrl
    }
    
}
