//
//  CalendarViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class CalendarViewController: UIViewController, MNCalendarViewDelegate {
    private var eventCalendar: EventCalendar
    private weak var calendarView: CalendarView?
    private var hasScrolledToToday: Bool = false
    
    init() {
        self.eventCalendar = EventCalendar()
        super.init(nibName: nil, bundle: nil)
        self.title = "Events"
        self.tabBarItem.image = UIImage(named: "tabEvents")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.edgesForExtendedLayout = .None
        self.extendedLayoutIncludesOpaqueBars = false
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor(white: 0.97, alpha: 1)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Today", style: .Plain, target: self, action: "scrollToTodayAnimated")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "invokeSearch")
        
        let calendarView = CalendarView(frame: self.view.bounds)
        calendarView.delegate = self
        calendarView.calendar = self.eventCalendar.calendar
        calendarView.eventCalendar = self.eventCalendar
        calendarView.selectedDate = NSDate()
        calendarView.separatorColor = UIColor(white: 0, alpha: 0.1)
        calendarView.collectionView.scrollsToTop = false
        calendarView.registerUICollectionViewClasses()
        self.view.addSubview(calendarView)
        self.calendarView = calendarView
        
        let fromDateComponents = NSDateComponents()
        fromDateComponents.year = 2011
        calendarView.fromDate = calendarView.calendar.dateFromComponents(fromDateComponents)
        
        let toDateComponents = NSDateComponents()
        toDateComponents.year = 2
        calendarView.toDate = calendarView.calendar.dateByAddingComponents(toDateComponents, toDate: NSDate(), options: [])
        calendarView.reloadData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.calendarView?.frame = self.view.bounds
        self.calendarView?.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !self.hasScrolledToToday {
            self.scrollToToday(false)
            self.hasScrolledToToday = true
        }
    }
    
    func scrollToToday(animated: Bool) {
        guard let calendarView = self.calendarView else { return }
        
        let dateComponents = calendarView.calendar.components(.Month, fromDate: calendarView.fromDate, toDate: NSDate(), options: [])
        let indexPath = NSIndexPath(forRow: 0, inSection: dateComponents.month)
        
        calendarView.selectedDate = NSDate()
        calendarView.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Top, animated: animated)
        calendarView.reloadData()
    }
    
    func scrollToTodayAnimated() {
        self.scrollToToday(true)
    }
    
    func invokeSearch() {
        let viewController = CalendarSearchViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .Popover
        navigationController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func indexPathForDate(date: NSDate) -> NSIndexPath? {
        guard let calendarView = self.calendarView else { return nil }
        
        let difference = self.eventCalendar.calendar.components(.Month, fromDate: calendarView.fromDate, toDate: date, options: [])
        let section = difference.month
        
        let components = self.eventCalendar.calendar.components([.Day, .Weekday], fromDate: date)
        let daysInWeek = 7
        let item = daysInWeek + components.day + components.weekday
        
        return NSIndexPath(forItem: item, inSection: section)
    }
    
    // MARK: MNCalendarViewDelegate
    func calendarView(calendarView: MNCalendarView, didSelectDate date: NSDate) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), { () -> Void in
            let viewController = CalendarDayViewController(date: date)
            
            if self.traitCollection.horizontalSizeClass == .Regular {
                let indexPath = self.indexPathForDate(date)!
                let cell = calendarView.collectionView.cellForItemAtIndexPath(indexPath)
                let navigationController = UINavigationController(rootViewController: viewController)
                navigationController.modalPresentationStyle = .Popover
                navigationController.popoverPresentationController?.sourceView = cell
                navigationController.popoverPresentationController?.sourceRect = cell!.bounds
                self.presentViewController(navigationController, animated: true, completion: nil)
            } else {
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        })
    }
    
    // MARK: Calendar View
    class CalendarView: MNCalendarView {
        weak var eventCalendar: EventCalendar?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.dayCellClass = DayCell.self
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
            if let dayCell = cell as? DayCell {
                dayCell.hasEvents = (self.eventCalendar == nil ? false : self.eventCalendar!.eventsOccurOnDate(dayCell.date))
            }
            return cell
        }
        
        override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
            guard let cell = cell as? DayCell else { return }
            guard let eventCalendar = self.eventCalendar else { return }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                eventCalendar.fetchEventOccurrences(cell.date, completionHandler: { (fetched, error) -> Void in
                    if fetched && error == nil {
                        dispatch_async(dispatch_get_main_queue(), {
                            let components = eventCalendar.calendar.components(.Month, fromDate: self.fromDate, toDate: cell.date, options: [])
                            let section = (components.month + 1)
                            let numberOfCells = collectionView.numberOfItemsInSection(section)
                            
                            for i in 1...numberOfCells {
                                let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: i - 1, inSection: section))
                                if let dayCell = cell as? DayCell {
                                    dayCell.hasEvents = eventCalendar.eventsOccurOnDate(dayCell.date)
                                }
                            }
                        })
                    }
                })
            })
        }
        
        class DayCell: MNCalendarViewDayCell {
            var hasEvents: Bool = false {
                didSet {
                    self.setNeedsDisplay()
                }
            }
            
            private var selectedColor: UIColor?
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                self.selectedColor = self.selectedBackgroundView?.backgroundColor
                self.selectedBackgroundView = nil
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            override func layoutSubviews() {
                super.layoutSubviews()
                
                if self.traitCollection.horizontalSizeClass == .Regular {
                    self.titleLabel.font = UIFont.systemFontOfSize(18)
                }
            }
            
            override var highlighted: Bool {
                didSet {
                    self.backgroundColor = (highlighted ? self.selectedColor : UIColor.whiteColor())
                }
            }
            
            override var selected: Bool {
                didSet {
                    self.backgroundColor = (selected ? self.selectedColor : UIColor.whiteColor())
                }
            }
            
            override func drawRect(rect: CGRect) {
                super.drawRect(rect)
                
                if self.hasEvents && self.enabled {
                    UIColor.redColor().set()
                    let size = floor(self.bounds.size.height * 0.15)
                    let path = UIBezierPath()
                    path.moveToPoint(CGPoint(x: self.frame.size.width, y: 0))
                    path.addLineToPoint(CGPoint(x: self.frame.size.width, y: size))
                    path.addLineToPoint(CGPoint(x: self.frame.size.width - size, y: 0))
                    path.closePath()
                    path.fill()
                }
            }
        }
    }
}
