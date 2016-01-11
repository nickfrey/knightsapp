//
//  RemoteImageView.swift
//  Newman Knights
//
//  Created by Nick Frey on 1/10/16.
//  Copyright © 2016 Nick Frey. All rights reserved.
//

import UIKit

class RemoteImageView: UIImageView {
    weak var imageCache: NSCache?
    private var dataTask: NSURLSessionDataTask?
    private weak var indicatorView: UIActivityIndicatorView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        indicatorView.hidesWhenStopped = true
        self.addSubview(indicatorView)
        self.indicatorView = indicatorView
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let indicatorView = self.indicatorView {
            let indicatorSize = indicatorView.frame.size
            indicatorView.frame = CGRectMake(
                (CGRectGetWidth(self.frame) - indicatorSize.width)/2,
                (CGRectGetHeight(self.frame) - indicatorSize.height)/2,
                indicatorSize.width,
                indicatorSize.height
            )
        }
    }
    
    func updateImage(URL: NSURL?, transition: Bool, completionHandler: (() -> Void)?) {
        if let dataTask = self.dataTask {
            dataTask.cancel()
            self.dataTask = nil
        }
        
        guard let imageURL = URL else {
            return UIView.transitionWithView(self, duration: (transition ? 0.5 : 0), options: .TransitionCrossDissolve, animations: { () -> Void in
                self.image = nil
            }, completion: { (completed) -> Void in
                completionHandler?()
            })
        }
        
        if let cachedImage = self.imageCache?.objectForKey(imageURL) {
            UIView.transitionWithView(self, duration: (transition ? 0.5 : 0), options: .TransitionCrossDissolve, animations: { () -> Void in
                self.image = cachedImage as? UIImage
            }, completion: { (completed) -> Void in
                completionHandler?()
            })
        } else {
            if !transition {
                self.image = nil
            }
            
            self.indicatorView?.startAnimating()
            self.dataTask = NSURLSession.sharedSession().dataTaskWithURL(imageURL, completionHandler: { (data, response, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    self.indicatorView?.stopAnimating()
                    guard let data = data where error == nil else {
                        completionHandler?()
                        return
                    }
                    
                    if let image = UIImage(data: data) {
                        self.imageCache?.setObject(image, forKey: imageURL)
                        UIView.transitionWithView(self, duration: (transition ? 0.5 : 0), options: .TransitionCrossDissolve, animations: { () -> Void in
                            self.image = image
                        }, completion: { (completed) -> Void in
                            completionHandler?()
                        })
                    }
                })
            })
            self.dataTask?.resume()
        }
    }
}