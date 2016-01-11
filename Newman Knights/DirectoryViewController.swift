//
//  DirectoryViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 1/2/16.
//  Copyright © 2016 Nick Frey. All rights reserved.
//

import UIKit
import MessageUI

class DirectoryViewController: FetchedViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate {
    private let directory: Contact.Directory
    private var contacts: Array<Contact> = []
    private weak var tableView: UITableView?
    
    init(directory: Contact.Directory) {
        self.directory = directory
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        switch self.directory {
        case .Administration:
            self.title = "Administration"
        case .Office:
            self.title = "Office"
        case .Faculty:
            self.title = "Teachers"
        }
        
        let tableView = UITableView(frame: CGRectZero, style: .Grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.hidden = true
        tableView.rowHeight = 50
        self.view.addSubview(tableView)
        self.view.sendSubviewToBack(tableView)
        self.tableView = tableView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView?.frame = self.view.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.performSelector("fetch", withObject: nil, afterDelay: 0.2)
    }
    
    override func fetch() {
        self.tableView?.hidden = true
        super.fetch()
        
        DataSource.fetchContacts(self.directory) { (contacts, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                guard let contacts = contacts where error == nil else {
                    let fallbackError = NSError(
                        domain: NSURLErrorDomain,
                        code: NSURLErrorUnknown,
                        userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
                    )
                    return self.fetchFinished(error == nil ? fallbackError : error)
                }
                
                self.contacts = contacts
                self.fetchFinished(nil)
                self.tableView?.reloadData()
                self.tableView?.hidden = false
            })
        }
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
            cell?.accessoryType = .DisclosureIndicator
        }
        
        let contact = self.contacts[indexPath.row]
        cell!.textLabel?.text = contact.name
        cell!.detailTextLabel?.text = contact.title
        
        return cell!
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let contact = self.contacts[indexPath.row]
        let email = "\"" + contact.name + "\" <" + contact.email + ">"
        
        if MFMailComposeViewController.canSendMail() {
            let viewController = MFMailComposeViewController()
            viewController.mailComposeDelegate = self
            viewController.setToRecipients([email])
            viewController.navigationBar.barStyle = .Black
            viewController.navigationBar.tintColor = UIColor.whiteColor()
            self.presentViewController(viewController, animated: true, completion: { () -> Void in
                UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
            })
        } else if let mailtoURL = NSURL(string: "mailto://" + contact.email) {
            UIApplication.sharedApplication().openURL(mailtoURL)
        }
    }
    
    // MARK: MFMailComposeViewControllerDelegate
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
