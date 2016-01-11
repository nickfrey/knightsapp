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
        super.init(URL: NSURL(string: AppConfiguration.PowerSchoolURLString)!)
        self.title = "Grades"
        self.tabBarItem.image = UIImage(named: "tabGrades")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: UIImage(named: "gradesBack"), style: .Plain, target: self.webView, action: "goBack"),
            UIBarButtonItem(image: UIImage(named: "gradesForward"), style: .Plain, target: self.webView, action: "goForward")
        ]
        
        for barButtonItem in self.navigationItem.leftBarButtonItems! {
            barButtonItem.enabled = false
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
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let superImplementation = {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        
        guard let keyPath = keyPath else { return superImplementation() }
        guard let object = object as? NSObject else { return superImplementation() }
        guard let webView = self.webView where object == webView else { return superImplementation() }
        
        if keyPath == "canGoBack" {
            self.navigationItem.leftBarButtonItems?.first?.enabled = webView.canGoBack
        } else if keyPath == "canGoForward" {
            self.navigationItem.leftBarButtonItems?.last?.enabled = webView.canGoForward
        } else if keyPath == "loading" {
            if webView.loading {
                let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
                indicatorView.startAnimating()
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicatorView)
            } else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self.webView, action: "reload")
            }
        } else {
            superImplementation()
        }
    }
}
