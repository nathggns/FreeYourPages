//
//  ViewController.swift
//  Scribd Exporer
//
//  Created by Nathaniel Higgins on 27/12/2016.
//  Copyright © 2016 Nathaniel Higgins. All rights reserved.
//

import UIKit
import KeychainSwift
import SwiftyJSON
import PromiseKit

class ViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    weak var popupDelegate: PopupDelegate?


    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.becomeFirstResponder()
    }
    
    @IBAction func saveLogin() {
        let kc = KeychainSwift()
        kc.accessGroup = Bundle.main.object(forInfoDictionaryKey: "Keychain Group") as! String?
        
        if let email = emailField.text, let password = passwordField.text {
            let scribd = Scribd(email: email, password: password)
            
            _ = firstly { scribd.handleLogin() }
                .then { _ -> Void in
                    if !kc.set(email, forKey: "scribdEmail") || !kc.set(password, forKey: "scribdPassword") {
                        NSLog("Failed")
                    } else {
                        self.popupDelegate?.didFinish(sender: self)
                    }
                }
                .catch { _ in
                    let alert = UIAlertController(title: "Unable to login", message: "Your email or password are incorrect", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
        }
        
    }
    
    
    @IBAction func cancelLogin() {
        popupDelegate?.didCancel(sender: self)
    }
    
}

