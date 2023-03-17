//
//  ViewController.swift
//  Simple Stocks
//
//  Created by Sohan Kancherla on 11/6/22.
//

import UIKit
import Firebase

class ChangeViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var email_label: UILabel!
    @IBOutlet weak var line: UIView!
    @IBOutlet weak var alert: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.line.backgroundColor = .white
        email.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
            view.endEditing(true)
    }
    
    @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
    }
    
    @IBAction func change_email(_ sender: Any) {
        self.alert.isHidden = true
        guard let email = email.text else {
            // show an error message to the user
            return
        }
        
        Auth.auth().currentUser?.updateEmail(to: email) { (error) in
            if let error = error {
                self.alert.text = (error.localizedDescription)
                self.line.backgroundColor = .systemRed
                self.email_label.textColor = .systemRed
                self.alert.isHidden = false
                return
            }
            
            let emailViewController = self.storyboard?.instantiateViewController(withIdentifier: "email2") as! EmailViewController
            emailViewController.modalPresentationStyle = .fullScreen
            emailViewController.modalTransitionStyle = .crossDissolve
            self.present(emailViewController, animated: true, completion: nil)
        }
    }
    

}
