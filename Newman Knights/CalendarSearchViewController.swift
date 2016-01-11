//
//  CalendarSearchViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/24/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class CalendarSearchViewController: UITableViewController, UISearchBarDelegate {
    private weak var searchBar: UISearchBar?
    private var searchResults: Array<Event>?
    private var currentCancelHandler: (() -> Void)?
    
    private let noneCellIdentifier = "NoneCell"
    private let resultCellIdentifier = "ResultCell"
    
    override func loadView() {
        super.loadView()
        
        self.tableView.rowHeight = 55
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: self.noneCellIdentifier)
        self.tableView.registerClass(CalendarDayViewController.EventCell.self, forCellReuseIdentifier: self.resultCellIdentifier)
        
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.showsCancelButton = true
        searchBar.backgroundImage = UIImage()
        searchBar.tintColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        self.searchBar = searchBar
        
        let barWrapperView = UIView(frame: CGRectMake(0, 0, self.view.bounds.size.width - 15, 44))
        barWrapperView.addSubview(searchBar)
        searchBar.sizeToFit()
        
        self.navigationItem.titleView = barWrapperView
        
        UIBarButtonItem.swift_appearanceWhenContainedIn([UISearchBar.self]).tintColor = UIColor.whiteColor()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar?.becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.searchBar?.becomeFirstResponder()
    }
    
    func fetchResults() {
        guard let searchText = self.searchBar?.text where searchText.characters.count > 2
            else { return }
        
        if let cancelHandler = self.currentCancelHandler {
            cancelHandler()
        }
        
        self.currentCancelHandler = EventCalendar.fetchEvents(searchText) { (events, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                if error == nil {
                    self.searchResults = events
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    // MARK: UISearchBarDelegate
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "fetchResults", object: nil)
        self.performSelector("fetchResults", withObject: nil, afterDelay: 0.3)
    }
    
    // MARK: UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let searchResults = self.searchResults where searchResults.count > 0 {
            return searchResults.count
        }
        
        return (self.searchBar?.text?.characters.count > 0 ? 1 : 0)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let searchResults = self.searchResults where searchResults.count > 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(self.resultCellIdentifier, forIndexPath: indexPath) as! CalendarDayViewController.EventCell
            cell.event = searchResults[indexPath.row]
            cell.dateFormat = "MMMM d, yyyy h:mm a"
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(self.noneCellIdentifier, forIndexPath: indexPath)
            cell.backgroundColor = UIColor.clearColor()
            cell.selectionStyle = .None
            cell.textLabel?.textColor = UIColor(white: 0, alpha: 0.4)
            cell.textLabel?.textAlignment = .Center
            cell.textLabel?.text = "No events."
            return cell
        }
    }
    
    // MARK: UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let searchResults = self.searchResults where indexPath.row < searchResults.count
            else { return }
        
        let viewController = CalendarEventViewController(event: searchResults[indexPath.row])
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
