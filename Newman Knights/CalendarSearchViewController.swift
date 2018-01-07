//
//  CalendarSearchViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/24/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class CalendarSearchViewController: UITableViewController, UISearchBarDelegate {
    fileprivate weak var searchBar: UISearchBar?
    fileprivate var searchResults: Array<Event>?
    fileprivate var currentCancelHandler: (() -> Void)?
    
    fileprivate let noneCellIdentifier = "NoneCell"
    fileprivate let resultCellIdentifier = "ResultCell"
    
    override func loadView() {
        super.loadView()
        
        self.tableView.rowHeight = 55
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.noneCellIdentifier)
        self.tableView.register(CalendarDayViewController.EventCell.self, forCellReuseIdentifier: self.resultCellIdentifier)
        
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.showsCancelButton = true
        searchBar.backgroundImage = UIImage()
        searchBar.tintColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        self.searchBar = searchBar
        
        let barWrapperView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width - 15, height: 44))
        barWrapperView.addSubview(searchBar)
        searchBar.sizeToFit()
        
        self.navigationItem.titleView = barWrapperView
        
        UIBarButtonItem.swift_appearanceWhenContained(in: [UISearchBar.self]).tintColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar?.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.searchBar?.becomeFirstResponder()
    }
    
    @objc func fetchResults() {
        guard let searchText = self.searchBar?.text, searchText.count > 2
            else { return }
        
        if let cancelHandler = self.currentCancelHandler {
            cancelHandler()
        }
        
        self.currentCancelHandler = EventCalendar.fetchEvents(searchText) { (events, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error == nil {
                    self.searchResults = events
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    // MARK: UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fetchResults), object: nil)
        self.perform(#selector(fetchResults), with: nil, afterDelay: 0.3)
    }
    
    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let searchResults = self.searchResults, searchResults.count > 0 {
            return searchResults.count
        }
        
        if let searchText = self.searchBar?.text {
            return (searchText.count > 0 ? 1 : 0)
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let searchResults = self.searchResults, searchResults.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: self.resultCellIdentifier, for: indexPath) as! CalendarDayViewController.EventCell
            cell.event = searchResults[indexPath.row]
            cell.dateFormat = "MMMM d, yyyy h:mm a"
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: self.noneCellIdentifier, for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            cell.textLabel?.textColor = UIColor(white: 0, alpha: 0.4)
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = "No events."
            return cell
        }
    }
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let searchResults = self.searchResults, indexPath.row < searchResults.count
            else { return }
        
        let viewController = CalendarEventViewController(event: searchResults[indexPath.row])
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
