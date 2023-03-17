//
//  ViewController.swift
//  Simple Stocks
//
//  Created by Sohan Kancherla on 11/6/22.
//

import UIKit
import Firebase

class ResetViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var alert: UILabel!
    @IBOutlet weak var email_label: UILabel!
    @IBOutlet weak var line: UIView!
    
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
    }
    
    @IBAction func reset(_ sender: Any) {
        self.alert.isHidden = true
        guard let email = email.text else {
                // show an error message to the user
                return
            }
            
        Auth.auth().sendPasswordReset(withEmail: email){ (error) in
            if let error = error {
                // show an error message to the user
                self.alert.text = (error.localizedDescription)
                self.line.backgroundColor = .systemRed
                self.email_label.textColor = .systemRed
                self.alert.isHidden = false
                return
            }
            let emailViewController = self.storyboard?.instantiateViewController(withIdentifier: "email") as! EmailViewController
            emailViewController.modalPresentationStyle = .fullScreen
            emailViewController.modalTransitionStyle = .crossDissolve
            self.present(emailViewController, animated: true, completion: nil)
        }
    }
    

}

