//
//  WebViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: FetchedViewController, WKNavigationDelegate {
    private let initialURL: NSURL?
    private var hasLoaded: Bool = false
    private(set) weak var webView: WKWebView?
    
    init(URL: NSURL?) {
        self.initialURL = URL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "sharePressed")
        
        let webView = WKWebView()
        webView.hidden = true
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        self.view.sendSubviewToBack(webView)
        self.webView = webView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.webView?.frame = self.view.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetch()
    }
    
    // MARK: Sharing
    func sharableURL() -> NSURL? {
        return self.initialURL
    }
    
    func sharePressed() {
        guard let sharableURL = self.sharableURL()
            else { return }
        
        let viewController = UIActivityViewController(activityItems: [sharableURL], applicationActivities: nil)
        viewController.modalPresentationStyle = .Popover
        viewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        viewController.popoverPresentationController?.permittedArrowDirections = .Up
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    // MARK: Fetched View Controller
    override func fetch() {
        super.fetch()
        
        if let initialURL = self.initialURL {
            self.webView?.loadRequest(NSURLRequest(URL: initialURL))
        }
    }
    
    override func fetchFinished(error: NSError?) {
        super.fetchFinished(error)
        
        if !self.hasLoaded {
            if error == nil {
                self.hasLoaded = true
                self.webView?.hidden = false
            } else {
                self.webView?.hidden = true
            }
        }
    }
    
    // MARK: WKNavigationDelegate
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation) {
        self.fetchFinished(nil)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        self.fetchFinished(error)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation, withError error: NSError) {
        self.fetchFinished(error)
    }
}
