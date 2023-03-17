//
//  LoginViewController.swift
//  Simple Stocks
//
//  Created by Sohan Kancherla on 2/3/23.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var user_name: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var line1: UIView!
    @IBOutlet weak var line2: UIView!
    @IBOutlet weak var alert: UILabel!
    @IBOutlet weak var password_label: UILabel!
    @IBOutlet weak var email_label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.line1.backgroundColor = .white
        self.line2.backgroundColor = .white
        user_name.delegate = self
        password.delegate = self
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
    
    @IBAction func login_button(_ sender: UIButton) {
        self.alert.isHidden = true
        guard let email = user_name.text, let password = password.text else {
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            if error != nil {
                self?.alert.isHidden = false
                self?.line1.backgroundColor = .systemRed
                self?.line2.backgroundColor = .systemRed
                self?.email_label.textColor = .systemRed
                self?.password_label.textColor = .systemRed
                return
            }
            let homeViewController = strongSelf.storyboard?.instantiateViewController(withIdentifier: "Home") as! HomeViewController
            homeViewController.modalPresentationStyle = .fullScreen
            homeViewController.modalTransitionStyle = .crossDissolve
            strongSelf.present(homeViewController, animated: true, completion: nil)
        }
    }
}

