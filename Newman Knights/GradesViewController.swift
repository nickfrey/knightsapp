//
//  GradesViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class GradesViewController: WebViewController {
    init() {
        super.init(URL: URL(string: AppConfiguration.PowerSchoolURLString)!)
        self.title = "Grades"
        self.tabBarItem.image = UIImage(named: "tabGrades")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: UIImage(named: "gradesBack"), style: .plain, target: self.webView, action: #selector(UIWebView.goBack)),
            UIBarButtonItem(image: UIImage(named: "gradesForward"), style: .plain, target: self.webView, action: #selector(UIWebView.goForward))
        ]
        
        for barButtonItem in self.navigationItem.leftBarButtonItems! {
            barButtonItem.isEnabled = false
        }
        
        self.webView?.addObserver(self, forKeyPath: "canGoBack", options: [], context: nil)
        self.webView?.addObserver(self, forKeyPath: "canGoForward", options: [], context: nil)
        self.webView?.addObserver(self, forKeyPath: "loading", options: [], context: nil)
    }
    
    deinit {
        self.webView?.removeObserver(self, forKeyPath: "canGoBack")
        self.webView?.removeObserver(self, forKeyPath: "canGoForward")
        self.webView?.removeObserver(self, forKeyPath: "loading")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let superImplementation = {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
        guard let keyPath = keyPath else { return superImplementation() }
        guard let object = object as? NSObject else { return superImplementation() }
        guard let webView = self.webView, object == webView else { return superImplementation() }
        
        if keyPath == "canGoBack" {
            self.navigationItem.leftBarButtonItems?.first?.isEnabled = webView.canGoBack
        } else if keyPath == "canGoForward" {
            self.navigationItem.leftBarButtonItems?.last?.isEnabled = webView.canGoForward
        } else if keyPath == "loading" {
            if webView.isLoading {
                let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
                indicatorView.startAnimating()
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicatorView)
            } else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self.webView, action: #selector(UIWebView.reload))
            }
        } else {
            superImplementation()
        }
    }
}
