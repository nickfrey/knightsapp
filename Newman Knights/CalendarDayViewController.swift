//
//  CalendarDayViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/24/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class CalendarDayViewController: FetchedViewController, UITableViewDataSource, UITableViewDelegate {
    let date: Date
    fileprivate var events: Array<Event> = []
    fileprivate weak var tableView: UITableView?
    fileprivate let eventCellIdentifier = "Event"
    fileprivate let emptyCellIdentifier = "Empty"
    
    init(date: Date) {
        self.date = date
        super.init(nibName: nil, bundle: nil)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        self.title = dateFormatter.string(from: date)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(fetch))
        
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true
        tableView.rowHeight = 55
        tableView.register(EventCell.self, forCellReuseIdentifier: self.eventCellIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.emptyCellIdentifier)
        self.view.addSubview(tableView)
        self.tableView = tableView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView?.frame = self.view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            self.tableView?.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetch()
    }
    
    @objc override func fetch() {
        self.tableView?.isHidden = true
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        super.fetch()
        
        _ = EventCalendar.fetchEvents(self.date) { (events, error) -> Void in
            DispatchQueue.main.async(execute: {
                guard let events = events, error == nil else {
                    return self.fetchFinished(error)
                }
                
                self.events = events
                self.fetchFinished(nil)
                self.tableView?.reloadData()
                self.tableView?.isHidden = false
            })
        }
    }
    
    override func fetchFinished(_ error: Error?) {
        super.fetchFinished(error)
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(self.events.count, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.events.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: self.emptyCellIdentifier, for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            cell.textLabel?.textColor = UIColor(white: 0, alpha: 0.4)
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = "No events occur on this day."
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: self.eventCellIdentifier, for: indexPath) as! EventCell
            cell.event = self.events[indexPath.row]
            return cell
        }
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.events.count > 0 {
            let viewController = CalendarEventViewController(event: self.events[indexPath.row])
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    // MARK: Event Cell
    class EventCell: UITableViewCell {
        fileprivate let dateFormatter: DateFormatter
        
        var dateFormat = "h:mm a" {
            didSet {
                if dateFormat != oldValue {
                    self.dateFormatter.dateFormat = dateFormat
                    self.updateLabels()
                }
            }
        }
        
        var event: Event? {
            didSet {
                if event != oldValue {
                    self.updateLabels()
                }
            }
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            self.dateFormatter = DateFormatter()
            self.dateFormatter.dateFormat = self.dateFormat
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
            self.accessoryType = .disclosureIndicator
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func updateLabels() {
            guard let event = self.event else { return }
            var eventDetails = Array<String>()
            
            if let startDate = event.startDate {
                let startTime = self.dateFormatter.string(from: startDate)
                if startTime != "12:00 AM" {
                    eventDetails.append(startTime)
                }
            }
            
            if let location = event.location, location.count > 0 {
                if location != "Newman Catholic" {
                    eventDetails.append("@ " + location)
                }
            }
            
            if let details = event.details, eventDetails.count == 0 {
                eventDetails.append(details)
            }
            
            if let status = event.status, status.count > 0 {
                eventDetails.append("(" + status + ")")
            }
            
            self.textLabel?.text = event.computedTitle()
            self.detailTextLabel?.text = eventDetails.joined(separator: " ")
        }
    }
}
