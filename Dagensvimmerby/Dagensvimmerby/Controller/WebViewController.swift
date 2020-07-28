//
//  WebViewController.swift
//  Dagensvimmerby
//
//  Created by Carlos Martin (SE) on 25/10/2016.
//  Copyright © 2016 TUVA Sweden AB. All rights reserved.
//

import UIKit
import WebKit
import Foundation
import Parse

class WebViewController: UIViewController {
    static let RELOAD_TIME_LIMIT: Double = 15 * 60
    
    @IBOutlet weak var wkwvContainer: UIView!
    @IBOutlet weak var goBackButtonItem: UIBarButtonItem!
    @IBOutlet weak var goForwardButtonItem: UIBarButtonItem!
    @IBOutlet weak var reloadButtonItem: UIBarButtonItem!
    @IBOutlet weak var shareButtonItem: UIBarButtonItem!
    
    var wkWebView: WKWebView!
    var backgroundTimeStamp: TimeInterval = 0
    
    @IBAction func goBackAction(_ sender: AnyObject) {
        if wkWebView.canGoBack {
            wkWebView.goBack()
        }
    }
    
    @IBAction func goForwardAction(_ sender: AnyObject) {
        if wkWebView.canGoForward {
            wkWebView.goForward()
        }
    }
    
    @IBAction func reloadAction(_ sender: AnyObject) {
        wkWebView.reload()
    }
    
    @IBAction func shareAction(_ sender: Any) {
        func shareURL (sharingUrl: String?) {
            var sharingItems = [AnyObject]()
            if let currentUrl = sharingUrl {
                sharingItems.append(currentUrl as AnyObject)
            }
            
            let vc = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
            vc.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            self.present(vc, animated: true, completion: nil)
        }
        
        if let url = self.wkWebView.url?.absoluteString {
            shareURL(sharingUrl: url)
        }
    }
    
    var url: URL?
    var url_name: String = Bundle.main.infoDictionary!["WEB_URL"] as! String
    
    //progress var
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
        selector: #selector(applicationDidBecomeActive),
        name: UIApplication.didBecomeActiveNotification,
        object: nil)
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(applicationDidEnterBackground),
        name: UIApplication.didEnterBackgroundNotification,
        object: nil)
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = .audio
        } else {
            // Fallback on earlier versions
        }
        
        wkWebView = WKWebView(frame: wkwvContainer.bounds, configuration: config)
        wkWebView.navigationDelegate = self
        wkWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wkwvContainer.addSubview(wkWebView)
        
        wkWebView.allowsBackForwardNavigationGestures = true
        
        wkWebView.uiDelegate = self
        wkWebView.navigationDelegate = self
        
        let webViewKeyPathsToObserve = ["loading", "estimatedProgress"]
        for keyPath in webViewKeyPathsToObserve {
            wkWebView.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
        }
        
        self.loadWebData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc fileprivate func applicationDidEnterBackground() {
        backgroundTimeStamp = NSDate().timeIntervalSince1970
    }
    
    @objc fileprivate func applicationDidBecomeActive() {
        if (backgroundTimeStamp > 0 && (backgroundTimeStamp+WebViewController.RELOAD_TIME_LIMIT) <= NSDate().timeIntervalSince1970) {
            self.loadWebData()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
            
        case "loading":
            goBackButtonItem.isEnabled = wkWebView.canGoBack
            goForwardButtonItem.isEnabled = wkWebView.canGoForward
            
        case "estimatedProgress":
            goBackButtonItem.isEnabled = wkWebView.canGoBack
            goForwardButtonItem.isEnabled = wkWebView.canGoForward
            
            progressView.isHidden = wkWebView.estimatedProgress == 1
            progressView.progress = Float(wkWebView.estimatedProgress)
        default:
            break
        }
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
        wkWebView.load(URLRequest(url: self.url!))
    }
    
}

extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // show error dialog
        if error.localizedDescription == "A server with the specified hostname could not be found." {
            Alert.showFailiureAlert(message: "Sidan kunde inte hittas")
        }
        print(" >>>>>>> \(error.localizedDescription)")
    }
}

extension WebViewController {
    
    func cleanBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        if let installation = PFInstallation.current() {
            installation.badge = 0
            installation.saveInBackground()
        }
    }
}

