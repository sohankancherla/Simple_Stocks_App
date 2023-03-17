//
//  ViewController.swift
//  Simple Stocks
//
//  Created by Sohan Kancherla on 11/6/22.
//

import UIKit
import Firebase
import FirebaseFirestore


class SlideInFromRightTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

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

        // Set the initial position of the destination view to the right of the screen
        destinationView.frame.origin.x = containerView.frame.width

        // Animate the transition
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            // Slide the source view to the left
            sourceView.frame.origin.x = -containerView.frame.width

            // Slide the destination view to the left
            destinationView.frame.origin.x = 0
        }, completion: { finished in
            // Remove the source view from the container view
            sourceView.removeFromSuperview()

            // Call the completion handler to indicate that the transition is complete
            transitionContext.completeTransition(finished)
        })
    }

}

class SlideInFromLeftTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
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



class HomeViewController: UIViewController, UIViewControllerTransitioningDelegate, UITableViewDataSource, UITableViewDelegate, StockDetailDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var uiview: UIView!
    
    let cellSpacingHeight: CGFloat = 0
    var stockSymbols = [String]()
    var get_data = true
    
    func didDeleteStock() {
        // Reload the data in the table view
        get_data = true
        self.viewDidLoad()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Customize your home screen UI here
        // Show the loading screen
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwipeHandler))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwipeHandler))
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        if get_data == true {
            let db = Firestore.firestore()
            if let uid = Auth.auth().currentUser?.uid {
                db.collection("users").document(uid).getDocument { (document, error) in
                    if let document = document, document.exists {
                        let data = document.data()
                        self.stockSymbols = data?["stockList"] as? [String] ?? []
                        //print("Stock symbols: \(self.stockSymbols)")
                        self.tableView.reloadData()
                    } else {
                        print("Document does not exist")
                    }
                }
            }
            get_data = false
        }
        
        
    }
    
    func getPrice(for symbol: String, completion: @escaping (Double?, Double?, Error?) -> Void) {
        let apiKey = "cg59so9r01qi63pm8q5gcg59so9r01qi63pm8q60"
        let url = "https://finnhub.io/api/v1/quote?symbol=\(symbol)&token=\(apiKey)"
        
        guard let url = URL(string: url) else {
            let error = NSError(domain: "com.example.stockapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(nil, nil, error)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, nil, error)
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "com.example.stockapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data returned"])
                completion(nil, nil, error)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let price = json["c"] as? Double
                    let change = json["d"] as? Double
                    if let price = price, let change = change {
                        completion(price, change, nil)
                    } else {
                        let error = NSError(domain: "com.example.stockapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "No price data returned"])
                        completion(nil, nil, error)
                    }
                } else {
                    let error = NSError(domain: "com.example.stockapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON data"])
                    completion(nil, nil, error)
                }
            } catch {
                completion(nil, nil, error)
            }
        }
        
        task.resume()
    }

    
    func getCompanyName(for symbol: String, completion: @escaping (String?, Error?) -> Void) {
        let apiKey = "cg59so9r01qi63pm8q5gcg59so9r01qi63pm8q60"
        let url = "https://finnhub.io/api/v1/stock/profile2?symbol=\(symbol)&token=\(apiKey)"
        
        guard let url = URL(string: url) else {
            let error = NSError(domain: "com.example.stockapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(nil, error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "com.example.stockapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data returned"])
                completion(nil, error)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let companyName = json["name"] as? String
                    if let name = companyName {
                        completion(name, nil)
                    } else {
                        let error = NSError(domain: "com.example.stockapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "No company name data returned"])
                        completion(nil, error)
                    }
                } else {
                    let error = NSError(domain: "com.example.stockapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON data"])
                    completion(nil, error)
                }
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! StockCell
        let symbol = self.stockSymbols[indexPath.section]
        getPrice(for: symbol) { price, change, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let price = price, let change = change {
                DispatchQueue.main.async {
                    cell.symbolLabel.text = symbol
                    cell.priceLabel.text = "$" + String(format: "%.2f", price)
                    if change < 0 {
                        cell.changeLabel.text = String(format: "%.2f", change)
                        cell.backgroundColor = .systemRed
                    } else {
                        cell.changeLabel.text = "+" + String(format: "%.2f", change)
                        cell.backgroundColor = UIColor(named: "Color")
                    }
                    cell.layer.cornerRadius = 20
                    cell.clipsToBounds = true
                }
            }
        }
        
        getCompanyName(for: symbol) { name, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let name = name {
                DispatchQueue.main.async {
                    cell.nameLabel.text = name
                }
            }
        }
        
        return cell
    }



    // MARK: - UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.stockSymbols.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    @objc private func rightSwipeHandler(_ gestureRecognizer: UISwipeGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            // Present the search view controller
            let searchVC = storyboard?.instantiateViewController(withIdentifier: "Search") as! SearchViewController
            searchVC.modalPresentationStyle = .fullScreen
            searchVC.transitioningDelegate = self
            present(searchVC, animated: true, completion: nil)
        }
    }
    
    @objc private func leftSwipeHandler(_ gestureRecognizer: UISwipeGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            // Present the search view controller
            let searchVC = storyboard?.instantiateViewController(withIdentifier: "Profile") as! ProfileViewController
            searchVC.modalPresentationStyle = .fullScreen
            searchVC.transitioningDelegate = self
            present(searchVC, animated: true, completion: nil)
        }
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is ProfileViewController {
            return SlideInFromRightTransitionAnimator() // Use right transition for ProfileViewController
        } else if presented is SearchViewController {
            return SlideInFromLeftTransitionAnimator() // Use left transition for SearchViewController
        }
        return nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "s1",
           let destinationVC = segue.destination as? ProfileViewController {
            destinationVC.modalPresentationStyle = .fullScreen // Set the presentation style of the destination view controller
            destinationVC.transitioningDelegate = self // Set the transitioning delegate of the destination view controller
        }
        if segue.identifier == "s6",
           let destinationVC = segue.destination as? SearchViewController {
            destinationVC.modalPresentationStyle = .fullScreen // Set the presentation style of the destination view controller
            destinationVC.transitioningDelegate = self // Set the transitioning delegate of the destination view controller
        }
        if segue.identifier == "detail" {
            guard let stockDetailVC = segue.destination as? StockDetailVC else { return }
            stockDetailVC.delegate = self
            
            // Get the selected cell and cast it to a UITableViewCell
            guard let cell = sender as? StockCell else { return }
            
            // Get the data from the cell
            let symbol = cell.symbolLabel.text
            let change = cell.changeLabel.text
            let name = cell.nameLabel.text
            let price = cell.priceLabel.text
            
            // Set the data on the second view controller's properties
            stockDetailVC.symbol = symbol!
            stockDetailVC.change = Double(change!)!
            stockDetailVC.name = name!
            stockDetailVC.price = price!
        }
    }
    
    
}

