import UIKit
import KeychainSwift

class ScribdViewController: UIViewController, PopupDelegate {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var emailLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadLoginInfo()
    }
    
    func loadLoginInfo() {
        
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
    
    func login(withDefaultEmail defaultEmail: String? = nil) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "scribdLogin") as! ScribdLoginViewController
        vc.popupDelegate = self
        vc.defaultEmail = defaultEmail
        
        
        self.present(vc, animated: true, completion: nil)
    }
    
    func didFinish(sender: UIViewController) {
        sender.dismiss(animated: true, completion: nil)
        
        loadLoginInfo()
    }
    
    func didCancel(sender: UIViewController) {
        contentView.alpha = 0
        sender.dismiss(animated: true, completion: nil)
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
    
    @IBAction func logout() {
        let kc = KeychainSwift()
        kc.accessGroup = Bundle.main.object(forInfoDictionaryKey: "Keychain Group") as! String?
        
        let defaultEmail = kc.get("scribdEmail")
        
        if !kc.delete("scribdEmail") || !kc.delete("scribdPassword") {
            NSLog("Error logging out")
        } else {
            login(withDefaultEmail: defaultEmail)
        }
    }

}
