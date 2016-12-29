//
//  ScribdController.swift
//  Scribd Exporer
//
//  Created by Nathaniel Higgins on 28/12/2016.
//  Copyright © 2016 Nathaniel Higgins. All rights reserved.
//

import UIKit
import KeychainSwift

class ScribdController: UIViewController, PopupDelegate {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var emailLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        handleData()
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleData() {
        
        let kc = KeychainSwift()
        kc.accessGroup = Bundle.main.object(forInfoDictionaryKey: "Keychain Group") as! String?
        
        if let email = kc.get("scribdEmail"), let _ = kc.get("scribdPassword") {
            emailLabel.text = email
            contentView.alpha = 1
        } else {
            contentView.alpha = 0
            login()
        }
    }
    
    func login() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "scribdLogin") as! ViewController
        vc.popupDelegate = self
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func logout() {
        let kc = KeychainSwift()
        kc.accessGroup = Bundle.main.object(forInfoDictionaryKey: "Keychain Group") as! String?
        
        if !kc.delete("scribdEmail") || !kc.delete("scribdPassword") {
            NSLog("Error logging out")
        } else {
            login()
        }
    }
    
    func didFinish(sender: UIViewController) {
        sender.dismiss(animated: true, completion: nil)
        handleData()
    }
    
    func didCancel(sender: UIViewController) {
        contentView.alpha = 0
        sender.dismiss(animated: true, completion: nil)
        _ = navigationController?.popToRootViewController(animated: true)
    }

}
