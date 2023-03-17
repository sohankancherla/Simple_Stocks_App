//
//  ViewController.swift
//  Simple Stocks
//
//  Created by Sohan Kancherla on 11/6/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import Foundation


protocol StockDetailDelegate: AnyObject {
    func didDeleteStock()
}

class StockDetailVC: UIViewController {

    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nav_item: UINavigationItem!
    @IBOutlet weak var nav_bar: UINavigationBar!
    @IBOutlet weak var trash_button: UIBarButtonItem!
    @IBOutlet weak var company_name: UILabel!
    @IBOutlet weak var price_label: UILabel!
    @IBOutlet weak var change_label: UILabel!
    @IBOutlet weak var open_label: UILabel!
    @IBOutlet weak var volume_label: UILabel!
    @IBOutlet weak var high_label: UILabel!
    @IBOutlet weak var low_label: UILabel!
    @IBOutlet weak var market_cap_label: UILabel!
    @IBOutlet weak var avg_vol_label: UILabel!
    @IBOutlet weak var wh_label: UILabel!
    @IBOutlet weak var wl_label: UILabel!
    @IBOutlet weak var pe_label: UILabel!
    @IBOutlet weak var ps_label: UILabel!
    @IBOutlet weak var pb_label: UILabel!
    @IBOutlet weak var period_label: UILabel!
    @IBOutlet weak var buy_label: UILabel!
    @IBOutlet weak var strong_buy_label: UILabel!
    @IBOutlet weak var hold_label: UILabel!
    @IBOutlet weak var sell_label: UILabel!
    @IBOutlet weak var strong_sell: UILabel!
    @IBOutlet weak var day_label: UILabel!
    @IBOutlet weak var day_uc_label: UILabel!
    @IBOutlet weak var week_label: UILabel!
    @IBOutlet weak var week_uc_label: UILabel!
    @IBOutlet weak var month_label: UILabel!
    @IBOutlet weak var month_uc_label: UILabel!
    @IBOutlet weak var year_label: UILabel!
    @IBOutlet weak var year_uc_label: UILabel!
    @IBOutlet weak var buy_buton: UIButton!
    @IBOutlet weak var hold_button: UIButton!
    @IBOutlet weak var sell_button: UIButton!
    @IBOutlet weak var buyLabel: UILabel!
    @IBOutlet weak var sellLabel: UILabel!
    @IBOutlet weak var holdLabel: UILabel!
    @IBOutlet weak var headline1: UILabel!
    @IBOutlet weak var source1: UILabel!
    @IBOutlet weak var headline2: UILabel!
    @IBOutlet weak var source2: UILabel!
    @IBOutlet weak var headline3: UILabel!
    @IBOutlet weak var source3: UILabel!
    
    var fetchedNewsItems: [[String: Any]] = []
    var symbol = ""
    var change = 0.0
    var name = ""
    var price = ""
    let uid = Auth.auth().currentUser?.uid
    weak var delegate: StockDetailDelegate?
    
    struct Prediction: Codable {
        let direction: String
        let confidence: Double
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserVote(stockId: symbol, userId: uid!)
        trash_button.isHidden = false
        price_label.text = price
        if change < 0 {
            nav_bar.barTintColor = .systemRed
            price_label.textColor = .systemRed
            change_label.text = String(format: "%.2f", change)
            change_label.textColor = .systemRed
        }
        else{
            nav_bar.barTintColor = UIColor(named: "Color")
            price_label.textColor = UIColor(named: "Color")
            change_label.text = "+" + String(format: "%.2f", change)
            change_label.textColor = UIColor(named: "Color")
        }
        company_name.text = name
        let titleLabel = UILabel()
        titleLabel.text = symbol
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        let fontDescriptor = UIFontDescriptor(name: "AppleSDGothicNeo-Bold", size: 24)
        let boldFont = UIFont(descriptor: fontDescriptor, size: 0)
        titleLabel.font = boldFont
        titleLabel.sizeToFit()
        nav_item.titleView = titleLabel
        self.updateVoteLabels(stockId: symbol)

        
        // Fetch stock data
        let apiKey = "cg59so9r01qi63pm8q5gcg59so9r01qi63pm8q60"
        let quoteURL = "https://finnhub.io/api/v1/quote?symbol=\(symbol)&token=\(apiKey)"
        let currentTime = Int(Date().timeIntervalSince1970)
        let oneDayAgo = currentTime - 86400 // 86400 seconds in a day
        let candlesURL = "https://finnhub.io/api/v1/stock/candle?symbol=\(symbol)&resolution=1&from=\(oneDayAgo)&to=\(currentTime)&token=\(apiKey)"

        let profileURL = "https://finnhub.io/api/v1/stock/profile2?symbol=\(symbol)&token=\(apiKey)"
        let metricURL = "https://finnhub.io/api/v1/stock/metric?symbol=\(symbol)&metric=price&token=\(apiKey)"
        let metricURL2 = "https://finnhub.io/api/v1/stock/metric?symbol=\(symbol)&metric=valuation&token=\(apiKey)"
        let analystRatingsURL = "https://finnhub.io/api/v1/stock/recommendation?symbol=\(symbol)&token=\(apiKey)"
        
        let url = URL(string: "https://skancher.pythonanywhere.com/predict")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "symbol=\(symbol)".data(using: .utf8)


        let group = DispatchGroup()

        // Fetch quote data
        group.enter()
        if let url = URL(string: quoteURL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            DispatchQueue.main.async {
                                if let openPrice = json["o"] as? Double {
                                    // Update UI with open price
                                    self.open_label.text = String(format: "%.2f", openPrice)
                                }
                                if let high = json["h"] as? Double {
                                    // Update UI with high
                                    self.high_label.text = String(format: "%.2f", high)
                                }
                                if let low = json["l"] as? Double {
                                    // Update UI with low
                                    self.low_label.text = String(format: "%.2f", low)
                                }
                            }
                        }
                    } catch {
                        print("Error parsing quote JSON: \(error)")
                    }
                }
                group.leave()
            }.resume()
        }
        
        //get volume data
        group.enter()
        if let url = URL(string: candlesURL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            DispatchQueue.main.async {
                                if let volumes = json["v"] as? [Double] {
                                    let totalVolume = volumes.reduce(0, +) // Sum up all the volumes
                                    let volumeInMillions = totalVolume / 1_000_000 // Convert volume to millions
                                    // Update UI with total volume in millions
                                    self.volume_label.text = String(format: "%.2fM", volumeInMillions)
                                }
                            }
                        }
                    } catch {
                        print("Error parsing candles JSON: \(error)")
                    }
                }
                group.leave()
            }.resume()
        }


        
        // Fetch profile and metric data
        group.enter()
        if let url = URL(string: profileURL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            DispatchQueue.main.async {
                                if let marketCap = json["marketCapitalization"] as? Double {
                                    let marketCapInBillions = marketCap / 1000
                                    // Update UI with market cap
                                    let marketCapFormatted = String(format: "%.2f", marketCapInBillions)
                                    self.market_cap_label.text = "\(marketCapFormatted)B"
                                }
                            }
                        }
                    }
                    catch {
                        print("Error parsing profile JSON: (error)")
                    }
                }
                group.leave()
            }
            .resume()
        }
        
        //avg volume api
        group.enter()
        if let url = URL(string: metricURL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let metric = json["metric"] as? [String: Any] {
                            DispatchQueue.main.async {
                                if let avgVolume = metric["10DayAverageTradingVolume"] as? Double {
                                    // Update UI with average volume
                                    self.avg_vol_label.text = String(format: "%.2fM", avgVolume)
                                }
                                if let week52High = metric["52WeekHigh"] as? Double {
                                    // Update UI with 52-week high
                                    self.wh_label.text = String(format: "%.2f", week52High)
                                }
                                if let week52Low = metric["52WeekLow"] as? Double {
                                    // Update UI with 52-week low
                                    self.wl_label.text = String(format: "%.2f", week52Low)
                                }
                            }
                        }
                    } catch {
                        print("Error parsing metric JSON: \(error)")
                    }
                }
                group.leave()
            }.resume()
        }
        
        // Fetch key financial ratios
        group.enter()
        if let url = URL(string: metricURL2) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            if let metricData = json["metric"] as? [String: Any] {
                                DispatchQueue.main.async {
                                    if let peRatio = metricData["peNormalizedAnnual"] as? Double {
                                        // Update UI with P/E ratio
                                        self.pe_label.text = String(format: "%.2f", peRatio)
                                    }
                                    if let psRatio = metricData["psTTM"] as? Double {
                                        // Update UI with P/S ratio
                                        self.ps_label.text = String(format: "%.2f", psRatio)
                                    }
                                    if let dividendYield = metricData["currentDividendYieldTTM"] as? Double {
                                        // Update UI with dividend yield
                                        self.pb_label.text = String(format: "%.2f%%", dividendYield)
                                    }
                                }
                            }
                        }
                    } catch {
                        print("Error parsing metric JSON: \(error)")
                    }
                }
                group.leave()
            }.resume()
        }
        
        // Fetch analyst ratings data
        group.enter()
        if let url = URL(string: analystRatingsURL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                            if let mostRecentRating = json.first {
                                DispatchQueue.main.async {
                                    if let buy = mostRecentRating["buy"] as? Int,
                                       let hold = mostRecentRating["hold"] as? Int,
                                       let sell = mostRecentRating["sell"] as? Int,
                                       let strongBuy = mostRecentRating["strongBuy"] as? Int,
                                       let strongSell = mostRecentRating["strongSell"] as? Int,
                                       let period = mostRecentRating["period"] as? String {
                                        
                                        let components = period.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
                                        if components.count == 2 {
                                            let formattedPeriod = components[1]
                                            
                                            // Update UI with analyst ratings and period
                                            self.buy_label.text = "\(buy)"
                                            self.hold_label.text = "\(hold)"
                                            self.sell_label.text = "\(sell)"
                                            self.strong_buy_label.text = "\(strongBuy)"
                                            self.strong_sell.text = "\(strongSell)"
                                            self.period_label.text = "\(formattedPeriod)"
                                        }
                                    }
                                }
                            }

                        }
                    } catch {
                        print("Error parsing analyst ratings JSON: \(error)")
                    }
                }
                group.leave()
            }.resume()
        }
        
        //machine learning server
        group.enter()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error making request:", error)
                group.leave()
                return
            }

            if let data = data {
                do {
                    let predictions = try JSONDecoder().decode([String: Prediction].self, from: data)
                    DispatchQueue.main.async {
                        // Update UI with predictions
                        // Example: self.day_direction_label.text = "\(predictions["day"]?.direction ?? 0)"
                        self.day_label.text = predictions["day"]?.direction ?? "Unknown"
                        self.day_uc_label.text = String(format: "%.2f%%", predictions["day"]?.confidence ?? 0)
                        self.week_label.text = predictions["week"]?.direction ?? "Unknown"
                        self.week_uc_label.text = String(format: "%.2f%%", predictions["week"]?.confidence ?? 0)
                        self.month_label.text = predictions["month"]?.direction ?? "Unknown"
                        self.month_uc_label.text = String(format: "%.2f%%", predictions["month"]?.confidence ?? 0)
                        self.year_label.text = predictions["year"]?.direction ?? "Unknown"
                        self.year_uc_label.text = String(format: "%.2f%%", predictions["year"]?.confidence ?? 0)
                    }
                } catch {
                    print("Error decoding JSON1:", error)
                }
            }
            group.leave()
        }
        task.resume()

        group.enter()
        fetchNews(stockSymbol: symbol) { [weak self] newsItems in
            self?.fetchedNewsItems = newsItems
            self?.updateNewsLabels(newsItems: newsItems)
        }
        group.leave()
        
        group.notify(queue: .main) {
            print("All API requests completed")
        }

    }

    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func delete_stock(_ sender: Any) {
        let db = Firestore.firestore()
        if let uid = Auth.auth().currentUser?.uid {
            db.collection("users").document(uid).updateData([
                "stockList": FieldValue.arrayRemove([self.symbol])
            ])
            trash_button.isHidden = true
            delegate?.didDeleteStock()
        }
    }
    
    @IBAction func yahoo_finance(_ sender: UIButton) {
        let urlString = "https://finance.yahoo.com/quote/\(symbol)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func buy_vote(_ sender: UIButton) {
        updateVote(stockId: symbol, userId: uid!, vote: "buy")
        buy_buton.isHidden = true
        hold_button.isHidden = false
        sell_button.isHidden = false
    }
    
    @IBAction func hold_vote(_ sender: UIButton) {
        updateVote(stockId: symbol, userId: uid!, vote: "hold")
        buy_buton.isHidden = false
        hold_button.isHidden = true
        sell_button.isHidden = false
    }
    
    @IBAction func sell_vote(_ sender: UIButton) {
        updateVote(stockId: symbol, userId: uid!, vote: "sell")
        buy_buton.isHidden = false
        hold_button.isHidden = false
        sell_button.isHidden = true
    }
    
    func updateVote(stockId: String, userId: String, vote: String) {
        let db = Firestore.firestore()
        let stockRef = db.collection("stocks").document(stockId)

        stockRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                print("Error fetching document: \(error)")
                return
            }

            if let documentSnapshot = documentSnapshot, !documentSnapshot.exists {
                stockRef.setData([
                    "buy_count": 0,
                    "hold_count": 0,
                    "sell_count": 0,
                    "user_votes": [:]
                ]) { (error) in
                    if let error = error {
                        print("Error creating stock document: \(error)")
                    } else {
                        print("Stock document created successfully")
                        self.updateVote(stockId: stockId, userId: userId, vote: vote)
                    }
                }
            } else {
                db.runTransaction({ (transaction, errorPointer) -> Any? in
                    let stockDocument: DocumentSnapshot
                    do {
                        try stockDocument = transaction.getDocument(stockRef)
                    } catch let error as NSError {
                        errorPointer?.pointee = error
                        return nil
                    }

                    guard var stockData = stockDocument.data() else {
                        let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve stock from snapshot \(stockDocument)"])
                        errorPointer?.pointee = error
                        return nil
                    }

                    var userVotes = stockData["user_votes"] as? [String: String] ?? [:]
                    if let previousVote = userVotes[userId] {
                        if previousVote == vote {
                            // User has already voted for the same action, do nothing
                            return nil
                        } else {
                            // Update the previous vote count
                            stockData["\(previousVote)_count"] = (stockData["\(previousVote)_count"] as? Int ?? 0) - 1
                        }
                    }
                    userVotes[userId] = vote
                    stockData["user_votes"] = userVotes
                    stockData["\(vote)_count"] = (stockData["\(vote)_count"] as? Int ?? 0) + 1

                    transaction.setData(stockData, forDocument: stockRef)
                    return nil
                }) { (object, error) in
                    if let error = error {
                        print("Transaction failed: \(error)")
                    } else {
                        self.updateVoteLabels(stockId: stockId)
                    }
                }
            }
        }
    }

    func loadUserVote(stockId: String, userId: String) {
        let db = Firestore.firestore()
        let stockRef = db.collection("stocks").document(stockId)

        stockRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                print("Error fetching document: \(error)")
                return
            }

            if let documentSnapshot = documentSnapshot, documentSnapshot.exists {
                if let stockData = documentSnapshot.data(),
                   let userVotes = stockData["user_votes"] as? [String: String],
                   let userVote = userVotes[userId] {
                    
                    switch userVote {
                    case "buy":
                        self.buy_buton.isHidden = true
                        self.hold_button.isHidden = false
                        self.sell_button.isHidden = false
                    case "hold":
                        self.buy_buton.isHidden = false
                        self.hold_button.isHidden = true
                        self.sell_button.isHidden = false
                    case "sell":
                        self.buy_buton.isHidden = false
                        self.hold_button.isHidden = false
                        self.sell_button.isHidden = true
                    default:
                        self.buy_buton.isHidden = false
                        self.hold_button.isHidden = false
                        self.sell_button.isHidden = false
                    }
                }
            }
        }
    }
    
    func updateVoteLabels(stockId: String) {
        let db = Firestore.firestore()
        let stockRef = db.collection("stocks").document(stockId)

        stockRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                print("Error fetching document: \(error)")
                return
            }

            if let documentSnapshot = documentSnapshot, documentSnapshot.exists {
                if let stockData = documentSnapshot.data() {
                    let buyCount = stockData["buy_count"] as? Int ?? 0
                    let holdCount = stockData["hold_count"] as? Int ?? 0
                    let sellCount = stockData["sell_count"] as? Int ?? 0

                    let totalCount = buyCount + holdCount + sellCount
                    let buyPercentage = totalCount > 0 ? (Double(buyCount) / Double(totalCount)) * 100 : 0
                    let holdPercentage = totalCount > 0 ? (Double(holdCount) / Double(totalCount)) * 100 : 0
                    let sellPercentage = totalCount > 0 ? (Double(sellCount) / Double(totalCount)) * 100 : 0

                    self.buyLabel.text = String(format: "%.0f%%", buyPercentage)
                    self.holdLabel.text = String(format: "%.0f%%", holdPercentage)
                    self.sellLabel.text = String(format: "%.0f%%", sellPercentage)
                }
            }
        }
    }
    
    func fetchNews(stockSymbol: String, completion: @escaping ([[String: Any]]) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let currentDate = Date()
        let toDate = dateFormatter.string(from: currentDate)
        guard let fromDate = Calendar.current.date(byAdding: .year, value: -1, to: currentDate) else {
            print("Error calculating date")
            return
        }
        let fromDateString = dateFormatter.string(from: fromDate)

        let urlString = "https://finnhub.io/api/v1/company-news?symbol=\(stockSymbol)&from=\(fromDateString)&to=\(toDate)&token=cg59so9r01qi63pm8q5gcg59so9r01qi63pm8q60"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
            
            if let data = data {
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        let newsItems = Array(jsonArray.prefix(3))
                        completion(newsItems)
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }
        
        task.resume()
    }

    func updateNewsLabels(newsItems: [[String: Any]]) {
        DispatchQueue.main.async {
            if newsItems.indices.contains(0) {
                let newsItem1 = newsItems[0]
                self.headline1.text = newsItem1["headline"] as? String ?? "N/A"
                self.source1.text = newsItem1["source"] as? String ?? "N/A"
            }
            if newsItems.indices.contains(1) {
                let newsItem2 = newsItems[1]
                self.headline2.text = newsItem2["headline"] as? String ?? "N/A"
                self.source2.text = newsItem2["source"] as? String ?? "N/A"
            }
            if newsItems.indices.contains(2) {
                let newsItem3 = newsItems[2]
                self.headline3.text = newsItem3["headline"] as? String ?? "N/A"
                self.source3.text = newsItem3["source"] as? String ?? "N/A"
            }
        }
    }


    @IBAction func openURL1(_ sender: UIButton) {
        openURLForNewsItem(index: 0)
    }

    @IBAction func openURL2(_ sender: UIButton) {
        openURLForNewsItem(index: 1)
    }

    @IBAction func openURL3(_ sender: UIButton) {
        openURLForNewsItem(index: 2)
    }

    func openURLForNewsItem(index: Int) {
        if let urlString = fetchedNewsItems[index]["url"] as? String, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }



}
