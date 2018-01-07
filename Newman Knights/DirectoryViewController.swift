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
    fileprivate let directory: Contact.Directory
    fileprivate var contacts: Array<Contact> = []
    fileprivate weak var tableView: UITableView?
    
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
        case .administration:
            self.title = "Administration"
        case .office:
            self.title = "Office"
        case .faculty:
            self.title = "Teachers"
        }
        
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true
        tableView.rowHeight = 50
        self.view.addSubview(tableView)
        self.view.sendSubview(toBack: tableView)
        self.tableView = tableView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView?.frame = self.view.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.perform(#selector(fetch), with: nil, afterDelay: 0.2)
    }
    
    @objc override func fetch() {
        self.tableView?.isHidden = true
        super.fetch()
        
        DataSource.fetchContacts(self.directory) { (contacts, error) -> Void in
            DispatchQueue.main.async(execute: {
                guard let contacts = contacts, error == nil else {
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
                self.tableView?.isHidden = false
            })
        }
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell?.accessoryType = .disclosureIndicator
        }
        
        let contact = self.contacts[indexPath.row]
        cell!.textLabel?.text = contact.name
        cell!.detailTextLabel?.text = contact.title
        
        return cell!
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let contact = self.contacts[indexPath.row]
        let email = "\"" + contact.name + "\" <" + contact.email + ">"
        
        if MFMailComposeViewController.canSendMail() {
            let viewController = MFMailComposeViewController()
            viewController.mailComposeDelegate = self
            viewController.setToRecipients([email])
            viewController.navigationBar.barStyle = .black
            viewController.navigationBar.tintColor = .white
            self.present(viewController, animated: true, completion: { () -> Void in
                UIApplication.shared.setStatusBarStyle(.lightContent, animated: true)
            })
        } else if let mailtoURL = URL(string: "mailto://" + contact.email) {
            UIApplication.shared.openURL(mailtoURL)
        }
    }
    
    // MARK: MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}
