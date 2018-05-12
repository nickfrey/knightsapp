//
//  CalendarViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class CalendarViewController: UIViewController, MNCalendarViewDelegate, UIViewControllerPreviewingDelegate {
    fileprivate var eventCalendar: EventCalendar
    fileprivate weak var calendarView: CalendarView?
    fileprivate var hasScrolledToToday: Bool = false
    
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
        
        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars = false
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(scrollToTodayAnimated))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(invokeSearch))
        
        let calendarView = CalendarView(frame: self.view.bounds)
        calendarView.delegate = self
        calendarView.calendar = self.eventCalendar.calendar
        calendarView.eventCalendar = self.eventCalendar
        calendarView.selectedDate = Date()
        calendarView.separatorColor = UIColor(white: 0, alpha: 0.1)
        calendarView.collectionView.scrollsToTop = false
        calendarView.registerUICollectionViewClasses()
        self.view.addSubview(calendarView)
        self.calendarView = calendarView
        
        var fromDateComponents = DateComponents()
        fromDateComponents.year = 2011
        calendarView.fromDate = calendarView.calendar.date(from: fromDateComponents)
        
        var toDateComponents = DateComponents()
        toDateComponents.year = 2
        calendarView.toDate = calendarView.calendar.date(byAdding: toDateComponents, to: Date())
        calendarView.reloadData()
        
        registerForPreviewing(with: self, sourceView: calendarView.collectionView)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.calendarView?.frame = self.view.bounds
        self.calendarView?.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.hasScrolledToToday {
            self.scrollToToday(false)
            self.hasScrolledToToday = true
        }
    }
    
    func scrollToToday(_ animated: Bool) {
        guard let calendarView = self.calendarView else { return }
        
        let dateComponents = calendarView.calendar.dateComponents([.month], from: calendarView.fromDate, to: Date())
        let indexPath = IndexPath(row: 0, section: dateComponents.month!)
        
        calendarView.selectedDate = Date()
        calendarView.collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
        calendarView.reloadData()
    }
    
    @objc func scrollToTodayAnimated() {
        self.scrollToToday(true)
    }
    
    @objc func invokeSearch() {
        let viewController = CalendarSearchViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        navigationController.navigationBar.isTranslucent = false
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func indexPathForDate(_ date: Date) -> IndexPath? {
        guard let calendarView = self.calendarView else { return nil }
        let calendar = self.eventCalendar.calendar
        let differenceInMonthComponents = calendar.dateComponents([.month], from: calendarView.fromDate, to: date)
        let dayOfMonthComponents = calendar.dateComponents([.day], from: date)
        
        var firstOfMonthComponents = calendar.dateComponents([.month, .year], from: date)
        firstOfMonthComponents.day = 1
        
        let daysInWeek = 7 // Compensate for weekday title cells
        let weekdayOfFirstOfMonthComponents = calendar.dateComponents([.weekday], from: calendar.date(from: firstOfMonthComponents)!)
        return IndexPath(item: daysInWeek + (dayOfMonthComponents.day! - 1) + (weekdayOfFirstOfMonthComponents.weekday! - 1), section: differenceInMonthComponents.month!)
    }
    
    // MARK: MNCalendarViewDelegate
    func calendarView(_ calendarView: MNCalendarView, didSelect date: Date) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: { () -> Void in
            let viewController = CalendarDayViewController(date: date)
            
            if self.traitCollection.horizontalSizeClass == .regular {
                let indexPath = self.indexPathForDate(date)!
                let cell = calendarView.collectionView.cellForItem(at: indexPath)
                let navigationController = UINavigationController(rootViewController: viewController)
                navigationController.modalPresentationStyle = .popover
                navigationController.popoverPresentationController?.sourceView = cell
                navigationController.popoverPresentationController?.sourceRect = cell!.bounds
                navigationController.navigationBar.isTranslucent = false
                self.present(navigationController, animated: true, completion: nil)
            } else {
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        })
    }
    
    // MARK: UIViewControllerPreviewingDelegate
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard
            let calendarView = self.calendarView,
            let indexPath = calendarView.collectionView.indexPathForItem(at: location),
            let cell = calendarView.collectionView.cellForItem(at: indexPath) as? CalendarView.DayCell
            else { return nil }
        
        return CalendarDayViewController(date: cell.date)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
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
        
        override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
            if let dayCell = cell as? DayCell {
                if let eventCalendar = self.eventCalendar {
                    dayCell.hasEvents = eventCalendar.eventsOccurOnDate(dayCell.date)
                } else {
                    dayCell.hasEvents = false
                }
            }
            return cell
        }
        
        override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
            guard let cell = cell as? DayCell else { return }
            guard let eventCalendar = self.eventCalendar else { return }
            
            DispatchQueue.global().async(execute: {
                eventCalendar.fetchEventOccurrences(cell.date, completionHandler: { (fetched, error) -> Void in
                    if fetched && error == nil {
                        DispatchQueue.main.async(execute: {
                            for visibleCell in collectionView.visibleCells {
                                if let dayCell = visibleCell as? DayCell {
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
            
            fileprivate var selectedColor: UIColor?
            
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
                
                if self.traitCollection.horizontalSizeClass == .regular {
                    self.titleLabel.font = UIFont.systemFont(ofSize: 18)
                }
            }
            
            override var isHighlighted: Bool {
                didSet {
                    self.backgroundColor = (isHighlighted ? self.selectedColor : .white)
                }
            }
            
            override var isSelected: Bool {
                didSet {
                    self.backgroundColor = (isSelected ? self.selectedColor : .white)
                }
            }
            
            override func draw(_ rect: CGRect) {
                super.draw(rect)
                
                if self.hasEvents && self.isEnabled {
                    UIColor.red.set()
                    let size = floor(self.bounds.size.height * 0.15)
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: self.frame.size.width, y: 0))
                    path.addLine(to: CGPoint(x: self.frame.size.width, y: size))
                    path.addLine(to: CGPoint(x: self.frame.size.width - size, y: 0))
                    path.close()
                    path.fill()
                }
            }
        }
    }
}
