//
//  WebViewController.swift
//  Dagensvimmerby
//
//  Created by Carlos Martin (SE) on 25/10/2016.
//  Copyright © 2016 TUVA Sweden AB. All rights reserved.
//

import UIKit
import Foundation
import Parse

class WebViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var goBackButtonItem: UIBarButtonItem!
    @IBOutlet weak var goForwardButtonItem: UIBarButtonItem!
    @IBOutlet weak var reloadButtonItem: UIBarButtonItem!
    @IBOutlet weak var shareButtonItem: UIBarButtonItem!
    
    var before_stop: Int = 0
    var before_start: Int = 0
    var current_stop: Int = 0
    var current_start: Int = 0
    
    @IBAction func goBackAction(_ sender: AnyObject) {
        self.current_stop = 0
        self.current_start = 0
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @IBAction func goForwardAction(_ sender: AnyObject) {
        self.current_stop = 0
        self.current_start = 0
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @IBAction func reloadAction(_ sender: AnyObject) {
        self.current_stop = 0
        self.current_start = 0
        webView.reload()
    }
    
    @IBAction func shareAction(_ sender: Any) {
        func shareURL (sharingUrl: String?) {
            var sharingItems = [AnyObject]()
            if let currentUrl = sharingUrl {
                sharingItems.append(currentUrl as AnyObject)
            }
            let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
        }
        
        if let url = self.webView.request?.url?.absoluteString {
            shareURL(sharingUrl: url)
        }
    }
    
    var url: URL?
    var url_name: String = Bundle.main.infoDictionary!["WEB_URL"] as! String
    
    //progress var
    @IBOutlet weak var progressView: UIProgressView!
    var isLoaded: Bool?
    var timmer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.delegate = self
        
        self.loadWebData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.cleanBadge()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadWebData () {
        self.progressView.isHidden = true
        self.progressView.progress = 0.0
        
        goBackButtonItem.isEnabled = false
        goForwardButtonItem.isEnabled = false
        
        self.current_start = 0
        self.current_stop = 0
        
        if self.initWebData() {
            self.initWebView()
        }
    }
    
    func initWebData () -> Bool {
        let done: Bool
        if let _nurl = URL(string: self.url_name) {
            self.url = _nurl
            done = true
        } else {
            done = false
        }
        return done
    }
    
    func initWebView () {
        let request = URLRequest(url: self.url!)
        self.webView.loadRequest(request)
    }
    
}

extension WebViewController: UIWebViewDelegate {
    func webViewDidStartLoad(_ webView: UIWebView) {
        
        self.current_start += 1
        //print(" << Start: \(self.current_start)")
        if self.current_start == 1 {
            self.startLoading()
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.current_stop += 1
        //print(" >> Stop:  \(self.current_stop)")
        if self.current_stop == self.current_start {
            self.before_start = self.current_start
            self.before_stop = self.current_stop
            self.current_stop = 0
            self.current_start = 0
            self.stopLoading()
        }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        
        if error.localizedDescription == "A server with the specified hostname could not be found." {
            Alert.showFailiureAlert(message: "Sidan kunde inte hittas")
        }
        self.current_start -= 1
        print(" >>>>>>> \(error.localizedDescription)")
    }

}

extension WebViewController {
    func startLoading() {
        if self.progressView.isHidden {
            self.progressView.isHidden = false
        }
        self.progressView.progress = 0.0
        self.isLoaded = false
        self.timmer = Timer.scheduledTimer(timeInterval: 0.02667, target: self, selector: #selector(self.timerCallback), userInfo: nil, repeats: true)
    }
    func stopLoading() {
        self.isLoaded = true
        self.progressView.isHidden = true
        if webView.canGoBack {
            goBackButtonItem.isEnabled = true
        }
        
        if webView.canGoForward {
            goForwardButtonItem.isEnabled = true
        }
    }
    func timerCallback() {
        if self.isLoaded! {
            if self.progressView.progress >= 1 {
                //self.progressView.isHidden = true
                self.timmer?.invalidate()
            } else {
                self.progressView.progress += 0.1
            }
        } else {
            self.progressView.progress += 0.05
            if self.progressView.progress >= 0.95 {
                self.progressView.progress = 0.95
            }
        }
    }
    
    func cleanBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        if let installation = PFInstallation.current() {
            //installation.setDeviceTokenFrom(deviceToken)
            installation.badge = 0
            installation.saveInBackground()
        }
    }
}

