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
    fileprivate let initialURL: URL?
    fileprivate var hasLoaded: Bool = false
    fileprivate(set) weak var webView: WKWebView?
    
    init(URL: URL?) {
        self.initialURL = URL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(sharePressed))
        
        let webView = WKWebView()
        webView.isHidden = true
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        self.view.sendSubview(toBack: webView)
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
    func sharableURL() -> URL? {
        return self.initialURL
    }
    
    func sharePressed() {
        guard let sharableURL = self.sharableURL()
            else { return }
        
        let viewController = UIActivityViewController(activityItems: [sharableURL], applicationActivities: nil)
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        viewController.popoverPresentationController?.permittedArrowDirections = .up
        self.present(viewController, animated: true, completion: nil)
    }
    
    // MARK: Fetched View Controller
    override func fetch() {
        super.fetch()
        
        if let initialURL = self.initialURL {
            self.webView?.load(URLRequest(url: initialURL))
        }
    }
    
    override func fetchFinished(_ error: Error?) {
        super.fetchFinished(error)
        
        if !self.hasLoaded {
            if error == nil {
                self.hasLoaded = true
                self.webView?.isHidden = false
            } else {
                self.webView?.isHidden = true
            }
        }
    }
    
    // MARK: WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        self.fetchFinished(nil)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.fetchFinished(error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        self.fetchFinished(error)
    }
}
