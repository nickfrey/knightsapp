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
    fileprivate weak var loadingView: LoadingView?
    fileprivate weak var errorView: ErrorView?
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1)
        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars = false
        
        let loadingView = LoadingView()
        self.view.addSubview(loadingView)
        self.loadingView = loadingView
        
        let errorView = ErrorView()
        errorView.delegate = self
        errorView.isHidden = true
        self.view.addSubview(errorView)
        self.errorView = errorView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let loadingSize = CGSize(width: 100, height: 20)
        let errorSize = CGSize(width: 250, height: 190)
        let viewSize = self.view.bounds.size
        
        self.loadingView?.frame = CGRect(x: (viewSize.width - loadingSize.width)/2, y: (viewSize.height - loadingSize.height)/2, width: loadingSize.width, height: loadingSize.height)
        self.errorView?.frame = CGRect(x: (viewSize.width - errorSize.width)/2, y: (viewSize.height - errorSize.height)/2, width: errorSize.width, height: errorSize.height)
    }
    
    func fetch() {
        // Implemented by subclasses
        self.errorView?.isHidden = true
        self.loadingView?.isHidden = false
        self.fetching = true
    }
    
    func fetchFinished(_ error: Error?) {
        self.loadingView?.isHidden = true
        self.errorView?.isHidden = (error == nil)
        self.errorView?.message = error?.localizedDescription
        self.fetching = false
    }
    
    class LoadingView: UIView {
        fileprivate weak var indicatorView: UIActivityIndicatorView?
        fileprivate weak var indicatorLabel: UILabel?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            indicatorView.startAnimating()
            self.addSubview(indicatorView)
            self.indicatorView = indicatorView
            
            let indicatorLabel = UILabel()
            indicatorLabel.text = "Loading..."
            indicatorLabel.font = UIFont.systemFont(ofSize: 14)
            indicatorLabel.textColor = .darkGray
            self.addSubview(indicatorLabel)
            self.indicatorLabel = indicatorLabel
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.indicatorView?.frame = CGRect(x: 0, y: (self.frame.height - 20)/2, width: 20, height: 20)
            self.indicatorLabel?.frame = CGRect(x: 28, y: 0, width: self.frame.width - 28, height: self.frame.height)
        }
    }
    
    class ErrorView: UIView {
        weak var delegate: FetchedViewController?
        var message: String? {
            didSet {
                if let message = message {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineSpacing = 4
                    paragraphStyle.alignment = .center
                    
                    let attributedString = NSMutableAttributedString(string: message)
                    attributedString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, message.characters.count))
                    self.errorLabel?.attributedText = attributedString
                } else {
                    self.errorLabel?.attributedText = nil
                }
            }
        }
        
        fileprivate weak var errorLabel: UILabel?
        fileprivate weak var imageView: UIImageView?
        fileprivate weak var retryButton: UIButton?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            let imageView = UIImageView()
            imageView.image = UIImage(named: "errorView")
            self.addSubview(imageView)
            self.imageView = imageView
            
            let retryButton = UIButton(type: .system)
            retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            retryButton.setTitle("Retry", for: UIControlState())
            retryButton.setTitleColor(UIColor(red: 0, green: 122/255, blue: 1, alpha: 1), for: UIControlState())
            retryButton.setBackgroundImage(UIImage(named: "roundedButton"), for: UIControlState())
            retryButton.addTarget(self, action: #selector(retryPressed), for: .touchUpInside)
            self.addSubview(retryButton)
            self.retryButton = retryButton
            
            let errorLabel = UILabel()
            errorLabel.numberOfLines = 4
            errorLabel.font = UIFont.systemFont(ofSize: 15)
            errorLabel.textColor = .darkGray
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
            let imageViewFrame = CGRect(x: (viewSize.width - 47)/2, y: 0, width: 47, height: 42)
            let errorLabelFrame = CGRect(x: 0, y: imageViewFrame.maxY, width: viewSize.width, height: viewSize.height - imageViewFrame.maxY - 50)
            
            self.imageView?.frame = imageViewFrame
            self.errorLabel?.frame = errorLabelFrame
            self.retryButton?.frame = CGRect(x: 0, y: errorLabelFrame.maxY + 10, width: viewSize.width, height: 50)
        }
    }
}
