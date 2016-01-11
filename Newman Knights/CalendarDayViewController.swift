//
//  CalendarDayViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/24/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class CalendarDayViewController: FetchedViewController, UITableViewDataSource, UITableViewDelegate {
    let date: NSDate
    private var events: Array<Event> = []
    private weak var tableView: UITableView?
    private let eventCellIdentifier = "Event"
    private let emptyCellIdentifier = "Empty"
    
    init(date: NSDate) {
        self.date = date
        super.init(nibName: nil, bundle: nil)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        
        self.title = dateFormatter.stringFromDate(date)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "fetch")
        
        let tableView = UITableView(frame: CGRectZero, style: .Grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.hidden = true
        tableView.rowHeight = 55
        tableView.registerClass(EventCell.self, forCellReuseIdentifier: self.eventCellIdentifier)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: self.emptyCellIdentifier)
        self.view.addSubview(tableView)
        self.tableView = tableView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView?.frame = self.view.bounds
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            self.tableView?.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetch()
    }
    
    override func fetch() {
        self.tableView?.hidden = true
        self.navigationItem.rightBarButtonItem?.enabled = false
        super.fetch()
        
        EventCalendar.fetchEvents(self.date) { (events, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                guard let events = events where error == nil else {
                    return self.fetchFinished(error)
                }
                
                self.events = events
                self.fetchFinished(nil)
                self.tableView?.reloadData()
                self.tableView?.hidden = false
            })
        }
    }
    
    override func fetchFinished(error: NSError?) {
        super.fetchFinished(error)
        self.navigationItem.rightBarButtonItem?.enabled = true
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(self.events.count, 1)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if self.events.count == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(self.emptyCellIdentifier, forIndexPath: indexPath)
            cell.backgroundColor = UIColor.clearColor()
            cell.selectionStyle = .None
            cell.textLabel?.textColor = UIColor(white: 0, alpha: 0.4)
            cell.textLabel?.textAlignment = .Center
            cell.textLabel?.text = "No events occur on this day."
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(self.eventCellIdentifier, forIndexPath: indexPath) as! EventCell
            cell.event = self.events[indexPath.row]
            return cell
        }
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.events.count > 0 {
            let viewController = CalendarEventViewController(event: self.events[indexPath.row])
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    // MARK: Event Cell
    class EventCell: UITableViewCell {
        private let dateFormatter: NSDateFormatter
        
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
            self.dateFormatter = NSDateFormatter()
            self.dateFormatter.dateFormat = self.dateFormat
            super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
            self.accessoryType = .DisclosureIndicator
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func updateLabels() {
            guard let event = self.event else { return }
            var eventDetails = Array<String>()
            
            if let startDate = event.startDate {
                let startTime = self.dateFormatter.stringFromDate(startDate)
                if startTime != "12:00 AM" {
                    eventDetails.append(startTime)
                }
            }
            
            if let location = event.location where location.characters.count > 0 {
                if location != "Newman Catholic" {
                    eventDetails.append("@ " + location)
                }
            }
            
            if let details = event.details where eventDetails.count == 0 {
                eventDetails.append(details)
            }
            
            if let status = event.status where status.characters.count > 0 {
                eventDetails.append("(" + status + ")")
            }
            
            self.textLabel?.text = event.computedTitle()
            self.detailTextLabel?.text = eventDetails.joinWithSeparator(" ")
        }
    }
}
