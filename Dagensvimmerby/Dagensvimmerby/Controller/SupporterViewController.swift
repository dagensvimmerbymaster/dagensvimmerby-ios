//
//  SupporterViewController.swift
//  Dagensvimmerby
//
//  Created by Christoffer Assgård on 2020-08-17.
//  Copyright © 2020 Dagens Vimmerby AB. All rights reserved.
//

import UIKit
import StoreKit
import Parse


class SupporterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SKProductsRequestDelegate {
    @IBOutlet weak var closeBtn: UIBarButtonItem!
    @IBOutlet weak var restoreBtn: UIBarButtonItem!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var imgViewHeight: NSLayoutConstraint!
    @IBOutlet weak var supporterImgView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var restoreButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var buyButtonColor: UIColor?;
    
    var productIdentifiers: Array<String> = Array()
    var products = [String: SKProduct]()
    
    let EXPIRE_KEY: String = "SUPPORTER_EXPIRE"
    
    var imageName: String = Bundle.main.infoDictionary!["SUPPORTER_IMAGE_NAME"] as! String
    var confimationString: String = (Bundle.main.infoDictionary!["SUPPORTER_TITLE_TEXT_DONE"] as! String).uppercased()
    var contentTitle: String = (Bundle.main.infoDictionary!["SUPPORTER_TITLE_TEXT"] as! String).uppercased()
    var contentBody: String = Bundle.main.infoDictionary!["SUPPORTER_BODY_TEXT"] as! String
    
    var restoring: Bool = false
    
    func setProductIdentifiers() {
        productIdentifiers = Array()
        let bundleIdentifier =  Bundle.main.bundleIdentifier!
        let identifiers: Array<String> = ["tier.1", "tier.2"]
        for identifer in identifiers {
            productIdentifiers.append(bundleIdentifier+"."+identifer)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setProductIdentifiers()
        
        buyButtonColor = buyButton.backgroundColor
        tableViewHeight.constant = CGFloat(3*50)
        
        let image: UIImage = UIImage(named: imageName)!
        let aspect = image.size.height/image.size.width
        
        imgViewHeight.constant = CGFloat(supporterImgView.frame.size.width*aspect)
        
        supporterImgView.image = image
        
        closeBtn.title = "Stäng"
        
        buyButton.isHidden = true
        tableView.isHidden = true
        titleLabel.text = ""
        bodyLabel.text = ""
        restoreBtn.isEnabled = false
        restoreBtn.title = ""

        setBuyButtonEnabled(enabled: false)
        
        SKPaymentQueue.default().add(self)
        
        let receiptString = receiptData()

        if (receiptString != nil) {
            // Purschased state.
            print("Might be purchased state")
            receiptValidation()
        } else {
            showBuy()
        }
    }
    
    func requestProducts() {
        let productsRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        productsRequest.delegate = self;
        productsRequest.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            for product in response.products {
                self.products[product.productIdentifier] = product
            }
            self.setBuyButtonEnabled(enabled: false)
            self.buyButton.isHidden = false
            self.tableView.isHidden = false
            self.restoreBtn.isEnabled = true
            self.restoreBtn.title = "Återställ"
            self.tableView.reloadData()
        }
    }
    
    func showBuy() {
        print("Showing buy")
        if (self.products.count < 1) {
            requestProducts()
        } else {
            let indexPath = self.tableView.indexPathForSelectedRow
            if ((indexPath) != nil) {
                setBuyButtonEnabled(enabled: true)
            } else {
                setBuyButtonEnabled(enabled: false)
            }
            self.tableView.isUserInteractionEnabled = true
            self.buyButton.isHidden = false
            self.tableView.isHidden = false
            restoreBtn.isEnabled = true
            restoreBtn.title = "Återställ"
        }
        setText()
    }
    
    func setText() {
        titleLabel.text = contentTitle
        bodyLabel.text = contentBody
    }
    
    func showConfimation() {
        setText()
        titleLabel.text = confimationString
            
        buyButton.isHidden = true
        tableView.isHidden = true
            
        scrollView.scrollToTop()
            
        restoreBtn.isEnabled = false
        restoreBtn.title = ""
    }
    
    @IBAction func closeOnTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setBuyButtonEnabled(enabled: Bool) {
        buyButton.isEnabled = enabled
        if (enabled){
            buyButton.backgroundColor = buyButtonColor
        } else {
            buyButton.backgroundColor = UIColor.systemGray
        }
    }
    
    @IBAction func buyOnTap(_ sender: Any) {
        setBuyButtonEnabled(enabled: false)
        self.tableView.isUserInteractionEnabled = false
        
        let sandbox = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
          /* check if we're in sandbox mode */

        if sandbox {
                /* remove all unfinished transactions older than 1 minute */
                for transaction in SKPaymentQueue.default().transactions
                {
                        if transaction.transactionDate == nil || transaction.transactionDate!.timeIntervalSinceNow < -60 {
                                SKPaymentQueue.default().finishTransaction(transaction)
                        }
                }
        }
        
        let delay = sandbox ? (Dispatch.DispatchTime.now() + 1.0) : Dispatch.DispatchTime.now()
        DispatchQueue.main.asyncAfter(deadline: delay) {
           if SKPaymentQueue.canMakePayments() {
               let paymentRequest = SKMutablePayment()
            let index = self.tableView.indexPathForSelectedRow!
            let productID = self.productIdentifiers[index.row]
               paymentRequest.productIdentifier = productID
               SKPaymentQueue.default().add(paymentRequest)
           } else {
               print("User unable to make payments")
           }
        }
    }
    
    @IBAction func restorePressed(_ sender: Any) {
        restoring = true
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ProductTableViewCell
        
        let productId: String = productIdentifiers[productIdentifiers.index(productIdentifiers.startIndex, offsetBy: indexPath.row)]
        let product: SKProduct = products[productId]!
        cell.mainLabel.text = product.productDescription

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setBuyButtonEnabled(enabled: true)
    }
    
    func receiptValidation() {
        
        let last_expire = readStringData(key: EXPIRE_KEY)
        let last_expire_int = Int64(last_expire) ?? 0
        if (last_expire_int > 0) {
            print(last_expire_int)
            let now = Int64(Date().timeIntervalSince1970) * 1000
            if (now < last_expire_int) {
                self.showConfimation()
                return
            }
        }
        
        let receiptString = receiptData()
        
        if (receiptString != nil) {
            PFCloud.callFunction(inBackground: "verifyReceipt", withParameters: ["receipt": receiptString!]) { (response: Any?, error: Error?) in
                if ((error) != nil) {
                    print("error")
                    // invalid
                    self.showBuy()
                } else {
                    print("should be successful here!!")
                    if response is Array<Any> {
                        if ((response as! Array<Any>).count > 0) {
                            let res = response as! Array<Any>
                            for obj in res {
                                if (obj is Dictionary<String, Any?>) {
                                    let expire = (obj as! Dictionary<String, Any?>)["expirationDate"]
                                    print(expire!!)
                                    let s: String = String(expire as! Int64)
                                    writeAnyData(key: self.EXPIRE_KEY, value: s)
                                }
                            }
                            self.showConfimation()
                        } else {
                            if (self.restoring) {
                                self.restoring = false
                                Alert.showFailiureAlert(message: "Återställning misslyckades")
                            }
                            self.showBuy()
                        }
                    } else {
                        if (self.restoring) {
                            self.restoring = false
                            Alert.showFailiureAlert(message: "Återställning misslyckades")
                        }
                        self.showBuy()
                    }
                }
            }
        } else {
            // invalid
            if (self.restoring) {
                self.restoring = false
                Alert.showFailiureAlert(message: "Återställning misslyckades")
            }
            self.showBuy()
        }
    }

}

extension SupporterViewController: SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if transaction.transactionState == .purchased {
                //if item has been purchased
                print("Transaction Successful")
                receiptValidation()
            } else if transaction.transactionState == .failed {
                print("Transaction Failed")
                if (self.restoring) {
                    self.restoring = false
                    Alert.showFailiureAlert(message: "Återställning misslyckades")
                }
                self.showBuy()
            } else if transaction.transactionState == .restored {
                print("restored")
                receiptValidation()
            }
        }
    }
    
    func receiptData() -> String? {
        // Get the receipt if it's available
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
            FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {

            print(appStoreReceiptURL.path)
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                print(receiptData)

                let receiptString = receiptData.base64EncodedString(options: [])
                //print(receiptString)

                return receiptString
            }
            catch { print("Couldn't read receipt data with error: " + error.localizedDescription) }
        }
        
        return nil
    }

    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print("removed transaction")
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("completed with error" + error.localizedDescription)
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("payment Queue finished")
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
        print("paymentQueue")
    }

}

extension SKProduct {
    
    var productDescription: String? {
        return localizedPrice! + " per månad"
    }

    var localizedPrice: String? {
        // Initialize Number Formatter
        let numberFormatter = NumberFormatter()

        // Configure Number Formatter
        numberFormatter.locale = priceLocale
        numberFormatter.numberStyle = .currency

        return numberFormatter.string(from: price)
    }

}

extension UIScrollView {
    func scrollToTop() {
        let desiredOffset = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(desiredOffset, animated: true)
   }
}
