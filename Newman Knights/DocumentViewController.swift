//
//  DocumentViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class DocumentViewController: WebViewController {
    fileprivate let documentIdentifier: String
    
    init(identifier: String) {
        self.documentIdentifier = identifier
        super.init(URL: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func fetch() {
        super.fetch()
        
        let URLString = "https://www.googleapis.com/drive/v2/files/" + self.documentIdentifier + "?key=" + AppConfiguration.GoogleDrive.APIKey + "&fields=exportLinks"
        let fetchURL = URL(string: URLString)!
        
        URLSession.shared.dataTask(with: fetchURL, completionHandler: { (data, response, error) -> Void in
            DispatchQueue.main.async(execute: {
                guard let data = data, error == nil else {
                    let fallbackError = NSError(
                        domain: NSURLErrorDomain,
                        code: NSURLErrorUnknown,
                        userInfo: [NSLocalizedDescriptionKey: "This document could not be located."]
                    )
                    return self.fetchFinished(error != nil ? error : fallbackError)
                }
                
                do {
                    let JSONObject = try JSONSerialization.jsonObject(with: data, options: [])
                    if let responseDictionary = JSONObject as? Dictionary<String, AnyObject> {
                        if let exportLinks = responseDictionary["exportLinks"] as? Dictionary<String, String> {
                            if let pdfURL = exportLinks["application/pdf"] {
                                if let pageURL = URL(string: pdfURL) {
                                    self.webView?.load(URLRequest(url: pageURL))
                                    return
                                }
                            }
                        }
                    }
                } catch _ {}
                
                let fallbackError = NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorBadServerResponse,
                    userInfo: [NSLocalizedDescriptionKey: "There was a bad response from the server. Please try again."]
                )
                self.fetchFinished(fallbackError)
            })
        }).resume()
    }
    
    override func sharableURL() -> URL? {
        return URL(string: "https://docs.google.com/document/d/" + self.documentIdentifier)
    }
}
