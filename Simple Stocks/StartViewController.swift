//
//  ViewController.swift
//  Simple Stocks
//
//  Created by Sohan Kancherla on 11/6/22.
//

import UIKit
import Firebase

class StartViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                // User is signed in. Show home screen
                let home = self.storyboard?.instantiateViewController(withIdentifier: "Home") as! HomeViewController
                home.modalPresentationStyle = .fullScreen
                self.present(home, animated: false, completion: nil)
            }
        }
    }
    
    
}

