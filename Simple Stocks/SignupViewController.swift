//
//  ViewController.swift
//  Simple Stocks
//
//  Created by Sohan Kancherla on 11/6/22.
//

import UIKit
import Firebase

class SignupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var email_label: UILabel!
    @IBOutlet weak var password_label: UILabel!
    @IBOutlet weak var line1: UIView!
    @IBOutlet weak var line2: UIView!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var alert: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.line1.backgroundColor = .white
        self.line2.backgroundColor = .white
        email.delegate = self
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
    
    @IBAction func signup(_ sender: UIButton) {
        self.alert.isHidden = true
        guard let email = email.text, let password = password.text else {
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            if error != nil {
                self?.alert.text = (error?.localizedDescription)
                self?.line1.backgroundColor = .systemRed
                self?.line2.backgroundColor = .systemRed
                self?.email_label.textColor = .systemRed
                self?.password_label.textColor = .systemRed
                self?.alert.isHidden = false
                return
            }
            let homeViewController = strongSelf.storyboard?.instantiateViewController(withIdentifier: "Home") as! HomeViewController
            homeViewController.modalPresentationStyle = .fullScreen
            homeViewController.modalTransitionStyle = .crossDissolve
            strongSelf.present(homeViewController, animated: true, completion: nil)
        }
    }
    

}

