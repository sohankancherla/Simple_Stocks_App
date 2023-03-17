//
//  ViewController.swift
//  Simple Stocks
//
//  Created by Sohan Kancherla on 11/6/22.
//

import UIKit
import Firebase

class SlideInFromLeftTransitionAnimator2: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3 // Set the duration of the animation
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Get the source and destination views
        guard let sourceView = transitionContext.view(forKey: .from),
              let destinationView = transitionContext.view(forKey: .to) else {
            return
        }
        
        // Get the container view and add the destination view to it
        let containerView = transitionContext.containerView
        containerView.addSubview(destinationView)
        
        // Set the initial position of the destination view to the left of the screen
        destinationView.frame.origin.x = -containerView.frame.width
        
        // Animate the transition
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            // Slide the source view to the right
            sourceView.frame.origin.x = containerView.frame.width
            
            // Slide the destination view to the right
            destinationView.frame.origin.x = 0
        }, completion: { finished in
            // Remove the source view from the container view
            sourceView.removeFromSuperview()
            
            // Call the completion handler to indicate that the transition is complete
            transitionContext.completeTransition(finished)
        })
    }
}


class ProfileViewController: UIViewController, UIViewControllerTransitioningDelegate {

    @IBOutlet weak var line1: UIView!
    @IBOutlet weak var email_label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        line1.backgroundColor = .white
        email_label.text = Auth.auth().currentUser?.email
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func handleSwipeGesture(_ gestureRecognizer: UISwipeGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            // Present the search view controller
            let homeVC = storyboard?.instantiateViewController(withIdentifier: "Home") as! HomeViewController
            homeVC.modalPresentationStyle = .fullScreen
            homeVC.transitioningDelegate = self
            present(homeVC, animated: true, completion: nil)
        }
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return SlideInFromLeftTransitionAnimator2()
        }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "s2",
           let destinationVC = segue.destination as? HomeViewController {
            destinationVC.modalPresentationStyle = .fullScreen // Set the presentation style of the destination view controller
            destinationVC.transitioningDelegate = self // Set the transitioning delegate of the destination view controller
        }
        if segue.identifier == "s5",
           let destinationVC = segue.destination as? SearchViewController {
            destinationVC.modalPresentationStyle = .fullScreen // Set the presentation style of the destination view controller
            destinationVC.transitioningDelegate = self // Set the transitioning delegate of the destination view controller
        }
    }
    
    @IBAction func sign_out(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            
            // Navigate to the new view controller (e.g. LoginViewController)
            let loginVC = storyboard?.instantiateViewController(withIdentifier: "Start") as! StartViewController
            loginVC.modalPresentationStyle = .fullScreen
            loginVC.modalTransitionStyle = .crossDissolve
            present(loginVC, animated: true, completion: nil)
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    

}
