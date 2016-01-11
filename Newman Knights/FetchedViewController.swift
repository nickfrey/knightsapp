//
//  FetchedViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class FetchedViewController: UIViewController {
    var fetching: Bool = false
    private weak var loadingView: LoadingView?
    private weak var errorView: ErrorView?
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1)
        self.edgesForExtendedLayout = .None
        self.extendedLayoutIncludesOpaqueBars = false
        
        let loadingView = LoadingView()
        self.view.addSubview(loadingView)
        self.loadingView = loadingView
        
        let errorView = ErrorView()
        errorView.delegate = self
        errorView.hidden = true
        self.view.addSubview(errorView)
        self.errorView = errorView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let loadingSize = CGSizeMake(100, 20)
        let errorSize = CGSizeMake(250, 190)
        let viewSize = self.view.bounds.size
        
        self.loadingView?.frame = CGRectMake((viewSize.width - loadingSize.width)/2, (viewSize.height - loadingSize.height)/2, loadingSize.width, loadingSize.height)
        self.errorView?.frame = CGRectMake((viewSize.width - errorSize.width)/2, (viewSize.height - errorSize.height)/2, errorSize.width, errorSize.height)
    }
    
    func fetch() {
        // Implemented by subclasses
        self.errorView?.hidden = true
        self.loadingView?.hidden = false
        self.fetching = true
    }
    
    func fetchFinished(error: NSError?) {
        self.loadingView?.hidden = true
        self.errorView?.hidden = (error == nil)
        self.errorView?.message = error?.localizedDescription
        self.fetching = false
    }
    
    class LoadingView: UIView {
        private weak var indicatorView: UIActivityIndicatorView?
        private weak var indicatorLabel: UILabel?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            indicatorView.startAnimating()
            self.addSubview(indicatorView)
            self.indicatorView = indicatorView
            
            let indicatorLabel = UILabel()
            indicatorLabel.text = "Loading..."
            indicatorLabel.font = UIFont.systemFontOfSize(14)
            indicatorLabel.textColor = UIColor.darkGrayColor()
            self.addSubview(indicatorLabel)
            self.indicatorLabel = indicatorLabel
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.indicatorView?.frame = CGRectMake(0, (CGRectGetHeight(self.frame) - 20)/2, 20, 20)
            self.indicatorLabel?.frame = CGRectMake(28, 0, CGRectGetWidth(self.frame) - 28, CGRectGetHeight(self.frame))
        }
    }
    
    class ErrorView: UIView {
        weak var delegate: FetchedViewController?
        var message: String? {
            didSet {
                if let message = message {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineSpacing = 4
                    paragraphStyle.alignment = .Center
                    
                    let attributedString = NSMutableAttributedString(string: message)
                    attributedString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, message.characters.count))
                    self.errorLabel?.attributedText = attributedString
                } else {
                    self.errorLabel?.attributedText = nil
                }
            }
        }
        
        private weak var errorLabel: UILabel?
        private weak var imageView: UIImageView?
        private weak var retryButton: UIButton?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            let imageView = UIImageView()
            imageView.image = UIImage(named: "errorView")
            self.addSubview(imageView)
            self.imageView = imageView
            
            let retryButton = UIButton(type: .System)
            retryButton.titleLabel?.font = UIFont.systemFontOfSize(16)
            retryButton.setTitle("Retry", forState: .Normal)
            retryButton.setTitleColor(UIColor(red: 0, green: 122/255, blue: 1, alpha: 1), forState: .Normal)
            retryButton.setBackgroundImage(UIImage(named: "roundedButton"), forState: .Normal)
            retryButton.addTarget(self, action: "retryPressed", forControlEvents: .TouchUpInside)
            self.addSubview(retryButton)
            self.retryButton = retryButton
            
            let errorLabel = UILabel()
            errorLabel.numberOfLines = 4
            errorLabel.font = UIFont.systemFontOfSize(15)
            errorLabel.textColor = UIColor.darkGrayColor()
            self.addSubview(errorLabel)
            self.errorLabel = errorLabel
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func retryPressed() {
            self.delegate?.fetch()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let viewSize = self.frame.size
            let imageViewFrame = CGRectMake((viewSize.width - 47)/2, 0, 47, 42)
            let errorLabelFrame = CGRectMake(0, CGRectGetMaxY(imageViewFrame), viewSize.width, viewSize.height - CGRectGetMaxY(imageViewFrame) - 50)
            
            self.imageView?.frame = imageViewFrame
            self.errorLabel?.frame = errorLabelFrame
            self.retryButton?.frame = CGRectMake(0, CGRectGetMaxY(errorLabelFrame) + 10, viewSize.width, 50)
        }
    }
}
