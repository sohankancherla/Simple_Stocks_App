//
//  ViewController.swift
//  Simple Stocks
//
//  Created by Sohan Kancherla on 11/6/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class SlideInFromRightTransitionAnimator2: NSObject, UIViewControllerAnimatedTransitioning {

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

class SearchViewController: UIViewController,UIViewControllerTransitioningDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, StockDetailDelegate {
    
    @IBOutlet weak var search_bar: UITextField!
    var symbols: [String] = []
    var symbols2: [String] = []
    var prices: [Double] = []
    var changes: [Double] = []
    var names: [String] = []
    var watch_list = [String]()
    
    @IBOutlet weak var table_view: UITableView!
    @IBOutlet weak var no_entries: UILabel!
    
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
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeGesture.direction = .left
        view.addGestureRecognizer(swipeGesture)
        
        search_bar.delegate = self
        table_view.dataSource = self
        table_view.delegate = self
        table_view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        
        table_view.automaticallyAdjustsScrollIndicatorInsets = false
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        if get_data == true {
            let db = Firestore.firestore()
            if let uid = Auth.auth().currentUser?.uid {
                db.collection("users").document(uid).getDocument { (document, error) in
                    if let document = document, document.exists {
                        let data = document.data()
                        self.watch_list = data?["stockList"] as? [String] ?? []
                    } else {
                        print("Document does not exist")
                    }
                }
            }
            get_data = false
        }
        
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only recognize the tap gesture if the user is not tapping on a cell
        if let indexPath = table_view.indexPathForRow(at: touch.location(in: table_view)) {
            return false
        }
        return true
    }
    
    func searchStockSymbols(companyName: String, completion: @escaping ([String]?) -> Void) {
        let apiKey = "HKX2PD1B170FFYED"
        let urlString = "https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords=\(companyName)&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard let jsonArray = json as? [String: Any], let symbolArray = jsonArray["bestMatches"] as? [[String: Any]] else {
                    completion(nil)
                    return
                }
                let symbols = symbolArray.compactMap { $0["1. symbol"] as? String }
                let symbols2 = symbols.filter { $0.rangeOfCharacter(from: CharacterSet(charactersIn: ".")) == nil }
                completion(symbols2)
            } catch {
                completion(nil)
            }
        }.resume()
    }
    
    func searchForCompany(_ name: String, completion: @escaping ([String]?) -> Void) {
        searchStockSymbols(companyName: name) { symbols in
            DispatchQueue.main.async {
                if let symbols = symbols {
                    completion(symbols)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let searchText = textField.text {
            self.symbols = []
            self.changes = []
            self.prices = []
            self.names = []
            self.table_view.reloadData()
            print("User searched for: \(searchText)")
            // Do whatever you need to do with the search text here
            searchForCompany(searchText) { symbols in
                if let symbols = symbols {
                    self.symbols2 = symbols
                    // Do whatever you need to do with the symbols array here
                    for i in self.symbols2.indices {
                        self.getPrice(for: self.symbols2[i]) { price, change, error in
                            if let error = error {
                                print("Error: \(error.localizedDescription)")
                            }
                            if let price = price, let change = change {
                                self.getCompanyName(for: self.symbols2[i]) { name, error in
                                        if let error = error {
                                            print("Error: \(error.localizedDescription)")
                                        }
                                        
                                        if let name = name {
                                            self.symbols.append(self.symbols2[i])
                                            self.prices.append(price)
                                            self.changes.append(change)
                                            self.names.append(name)
                                            DispatchQueue.main.async {
                                                self.table_view.reloadData()
                                            }
                                        }
                                    }
                            }
                        }
                    }
                } else {
                    print("No symbols found for \(searchText)")
                }
            }
            
        }
        textField.resignFirstResponder()
        return true
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


    @IBAction func add_cell(_ sender: UIButton) {
        guard let cell = sender.superview?.superview as? StockCell else {
            return
        }

        // get the symbolLabel from the cell
        let symbolText = cell.symbolLabel.text!

        // add the symbol to the stockSymbols array
        let db = Firestore.firestore()
        if let uid = Auth.auth().currentUser?.uid {
            db.collection("users").document(uid).updateData([
                "stockList": FieldValue.arrayUnion([symbolText])
            ])
            cell.add_button.isHidden = true
        }
        
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! StockCell
        let symbol = self.symbols[indexPath.section]
        let price = self.prices[indexPath.section]
        let change = self.changes[indexPath.section]
        let name = self.names[indexPath.section]
        
        if self.watch_list.contains(symbol) {
            cell.add_button.isHidden = true
        }
        else{
            cell.add_button.isHidden = false
        }
        
        
        cell.symbolLabel.text = symbol
        cell.priceLabel.text = "$" + String(format: "%.2f", price)
        if change < 0 {
            cell.changeLabel.text = String(format: "%.2f", change)
            cell.backgroundColor = .systemRed
        } else {
            cell.changeLabel.text = "+" + String(format: "%.2f", change)
            cell.backgroundColor = UIColor(named: "Color")

        }
        cell.nameLabel.text = name
        cell.layer.cornerRadius = 20
        cell.clipsToBounds = true
        
        return cell
    }



    // MARK: - UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.symbols.count == 0 {
            self.no_entries.isHidden = false
        }
        else{
            self.no_entries.isHidden = true
        }
        return self.symbols.count
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
            return SlideInFromRightTransitionAnimator2()
        }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "s3",
           let destinationVC = segue.destination as? HomeViewController {
            destinationVC.modalPresentationStyle = .fullScreen // Set the presentation style of the destination view controller
            destinationVC.transitioningDelegate = self // Set the transitioning delegate of the destination view controller
        }
        if segue.identifier == "s4",
           let destinationVC = segue.destination as? ProfileViewController {
            destinationVC.modalPresentationStyle = .fullScreen // Set the presentation style of the destination view controller
            destinationVC.transitioningDelegate = self // Set the transitioning delegate of the destination view controller
        }
        if segue.identifier == "detail2" {
            guard let stockDetailVC = segue.destination as? StockDetailVC2 else { return }
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
