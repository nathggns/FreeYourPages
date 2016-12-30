import UIKit
import KeychainSwift
import SwiftyJSON
import PromiseKit

class ScribdLoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    weak var popupDelegate: PopupDelegate?
    var defaultEmail: String?
    
    var loginRequest: Promise<Void>?
    var controls : [UIControl] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        controls = [ emailField, passwordField, loginButton ]
        
        emailField.text = defaultEmail
        
        if let _ = defaultEmail {
            passwordField.becomeFirstResponder()
            defaultEmail = nil
        } else {
            emailField.becomeFirstResponder()
        }
        
    }
    
    func setControlsEnabled(_ enabled: Bool) -> Void {
        for control in controls {
            control.isEnabled = enabled
        }
    }
    
    func showIncorrectLoginAlert() -> Void {
        let alert = UIAlertController(title: "Unable to login", message: "Your email or password are incorrect", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_: UIAlertAction!) in self.emailField.becomeFirstResponder() }
        
        alert.addAction(action)
        
        self.present(alert, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailField:
            passwordField.becomeFirstResponder()
            
        case passwordField:
            self.saveLogin()
            return true
            
        default:
            return true
        }
        
        return false
    }
    
    
    @IBAction func cancelLogin() {
        popupDelegate?.didCancel(sender: self)
    }
    
    
    @IBAction func saveLogin() {
        let kc = KeychainSwift()
        kc.accessGroup = Bundle.main.object(forInfoDictionaryKey: "Keychain Group") as! String?
        
        if let email = emailField.text, let password = passwordField.text {
            let scribd = Scribd(email: email, password: password)
            
            if let _ = loginRequest {
                return
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            setControlsEnabled(false)
            
            loginRequest = firstly { scribd.handleLogin() }
                .then { _ -> Void in
                    if !kc.set(email, forKey: "scribdEmail") || !kc.set(password, forKey: "scribdPassword") {
                        NSLog("Failed")
                    } else {
                        self.popupDelegate?.didFinish(sender: self)
                    }
                }
                .catch { _ in self.showIncorrectLoginAlert() }
                .always {
                    self.loginRequest = nil
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    self.setControlsEnabled(true)
            }
        }
    }
    
}

