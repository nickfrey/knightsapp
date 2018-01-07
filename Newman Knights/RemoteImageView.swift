//
//  RemoteImageView.swift
//  Newman Knights
//
//  Created by Nick Frey on 1/10/16.
//  Copyright © 2016 Nick Frey. All rights reserved.
//

import UIKit

class RemoteImageView: UIImageView {
    weak var imageCache: NSCache<AnyObject, AnyObject>?
    fileprivate var dataTask: URLSessionDataTask?
    fileprivate weak var indicatorView: UIActivityIndicatorView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
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
            indicatorView.frame = CGRect(
                x: (self.frame.width - indicatorSize.width)/2,
                y: (self.frame.height - indicatorSize.height)/2,
                width: indicatorSize.width,
                height: indicatorSize.height
            )
        }
    }
    
    func updateImage(_ URL: URL?, transition: Bool, completionHandler: (() -> Void)?) {
        if let dataTask = self.dataTask {
            dataTask.cancel()
            self.dataTask = nil
        }
        
        guard let imageURL = URL else {
            return UIView.transition(with: self, duration: (transition ? 0.5 : 0), options: .transitionCrossDissolve, animations: { () -> Void in
                self.image = nil
            }, completion: { (completed) -> Void in
                completionHandler?()
            })
        }
        
        if let cachedImage = self.imageCache?.object(forKey: imageURL as AnyObject) {
            UIView.transition(with: self, duration: (transition ? 0.5 : 0), options: .transitionCrossDissolve, animations: { () -> Void in
                self.image = cachedImage as? UIImage
            }, completion: { (completed) -> Void in
                completionHandler?()
            })
        } else {
            if !transition {
                self.image = nil
            }
            
            self.indicatorView?.startAnimating()
            self.dataTask = URLSession.shared.dataTask(with: imageURL, completionHandler: { (data, response, error) -> Void in
                DispatchQueue.main.async(execute: {
                    self.indicatorView?.stopAnimating()
                    guard let data = data, error == nil else {
                        completionHandler?()
                        return
                    }
                    
                    if let image = UIImage(data: data) {
                        self.imageCache?.setObject(image, forKey: imageURL as AnyObject)
                        UIView.transition(with: self, duration: (transition ? 0.5 : 0), options: .transitionCrossDissolve, animations: { () -> Void in
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
