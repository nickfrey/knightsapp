//
//  NewsViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit
import QuickLook

class NewsViewController: FetchedViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, QLPreviewControllerDataSource {
    private weak var tableView: UITableView?
    private weak var coverView: CoverView?
    private var coverViewPreviewItem: CoverView.PreviewItem?
    private var coverViewHeight: CGFloat = 150
    private var socialPosts: Array<SocialPost> = []
    private var todayEvents: Array<Event> = []
    private var tomorrowEvents: Array<Event> = []
    private var imageCache: NSCache
    private let eventCellIdentifier = "Event"
    private let socialCellIdentifier = "Social"
    private let emptyCellIdentifier = "Empty"
    
    init() {
        self.imageCache = NSCache()
        super.init(nibName: nil, bundle: nil)
        self.title = "Newman Catholic"
        self.tabBarItem.title = "News"
        self.tabBarItem.image = UIImage(named: "tabNews")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        if self.traitCollection.horizontalSizeClass == .Regular {
            self.coverViewHeight = 325
        }
        
        let tableView = UITableView(frame: CGRectZero, style: .Grouped)
        tableView.hidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = self.view.backgroundColor
        tableView.tableHeaderView = UIView(frame: CGRectMake(0, 0, 0, self.coverViewHeight))
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.coverViewHeight, 0, 0, 0)
        tableView.estimatedRowHeight = 50
        tableView.alwaysBounceVertical = true
        tableView.registerClass(SocialViewController.Cell.self, forCellReuseIdentifier: self.socialCellIdentifier)
        tableView.registerClass(CalendarDayViewController.EventCell.self, forCellReuseIdentifier: self.eventCellIdentifier)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: self.emptyCellIdentifier)
        self.view.addSubview(tableView)
        self.tableView = tableView
        
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        let coverView = CoverView()
        coverView.hidden = true
        coverView.delegate = self
        self.view.addSubview(coverView)
        self.coverView = coverView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.coverView?.frame = CGRectMake(0, 0, self.view.frame.size.width, self.coverViewHeight)
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "fetch", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func fetch() {
        super.fetch()
        DataSource.fetchSocialPosts(10) { (posts, error) -> Void in
            guard let posts = posts where error == nil else {
                return dispatch_async(dispatch_get_main_queue(), {
                    self.fetchFinished(error)
                })
            }
            
            EventCalendar.fetchEvents(NSDate(), completionHandler: { (todayEvents, error) -> Void in
                guard let todayEvents = todayEvents where error == nil else {
                    return dispatch_async(dispatch_get_main_queue(), {
                        self.fetchFinished(error)
                    })
                }
                
                let tomorrowDate = NSCalendar.currentCalendar().dateByAddingUnit(.Day, value: 1, toDate: NSDate(), options: [])
                EventCalendar.fetchEvents(tomorrowDate!, completionHandler: { (tomorrowEvents, error) -> Void in
                    dispatch_async(dispatch_get_main_queue(), {
                        guard let tomorrowEvents = tomorrowEvents where error == nil else {
                            return self.fetchFinished(error)
                        }
                        
                        self.socialPosts = posts
                        self.todayEvents = todayEvents
                        self.tomorrowEvents = tomorrowEvents
                        self.fetchFinished(nil)
                        
                        self.coverView?.update(posts)
                        self.tableView?.reloadData()
                        self.coverView?.hidden = false
                        self.tableView?.hidden = false
                    })
                })
            })
        }
    }
    
    func coverViewPressed() {
        guard let coverView = self.coverView else { return }
        guard let coverImage = coverView.currentImage else { return }
        
        let temporaryURL = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let imageURL = temporaryURL.URLByAppendingPathComponent("photo").URLByAppendingPathExtension("jpg")
        UIImageJPEGRepresentation(coverImage, 1)?.writeToURL(imageURL, atomically: false)
        self.coverViewPreviewItem = CoverView.PreviewItem(URL: imageURL, title: "Recently Tweeted")
        
        let viewController = PreviewController()
        viewController.dataSource = self
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    // MARK: QLPreviewControllerDelegate
    func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
        return self.coverViewPreviewItem!
    }
    
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
        return (self.coverViewPreviewItem == nil ? 0 : 1)
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return max(min(3, self.socialPosts.count), 1)
        } else if section == 1 {
            return max(self.todayEvents.count, 1)
        } else if section == 2 {
            return max(self.tomorrowEvents.count, 1)
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && self.socialPosts.count > 0 {
            return SocialViewController.Cell.heightForPost(self.socialPosts[indexPath.row], contentWidth: tableView.bounds.size.width)
        } else {
            return 55
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if self.socialPosts.count == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier(self.emptyCellIdentifier, forIndexPath: indexPath)
                cell.textLabel?.text = "No tweets to show."
                cell.selectionStyle = .None
                return cell
            }
            
            let cell = tableView.dequeueReusableCellWithIdentifier(self.socialCellIdentifier, forIndexPath: indexPath) as! SocialViewController.Cell
            cell.imageCache = self.imageCache
            cell.post = self.socialPosts[indexPath.row]
            return cell
        } else {
            let events = (indexPath.section == 1 ? self.todayEvents : self.tomorrowEvents)
            if events.count == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier(self.emptyCellIdentifier, forIndexPath: indexPath)
                cell.textLabel?.text = "No events to show."
                cell.selectionStyle = .None
                return cell
            }
            
            let cell = tableView.dequeueReusableCellWithIdentifier(self.eventCellIdentifier, forIndexPath: indexPath) as! CalendarDayViewController.EventCell
            cell.event = events[indexPath.row]
            return cell
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Recent Tweets"
        } else if section == 1 {
            return "Today"
        } else if section == 2 {
            return "Tomorrow"
        }
        
        return nil
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if self.socialPosts.count > 0 {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                self.socialPosts[indexPath.row].openInExternalApplication()
            }
        } else {
            let events = (indexPath.section == 1 ? self.todayEvents : self.tomorrowEvents)
            if events.count > 0 {
                let viewController = CalendarEventViewController(event: events[indexPath.row])
                
                if self.traitCollection.horizontalSizeClass == .Regular {
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    
                    let cell = tableView.cellForRowAtIndexPath(indexPath)
                    let navigationController = UINavigationController(rootViewController: viewController)
                    navigationController.modalPresentationStyle = .Popover
                    navigationController.popoverPresentationController?.sourceView = cell
                    navigationController.popoverPresentationController?.sourceRect = cell!.bounds
                    self.presentViewController(navigationController, animated: true, completion: nil)
                } else {
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard let coverView = self.coverView else { return }
        let scrollOffset = scrollView.contentOffset.y
        
        if scrollOffset < 0 {
            // Adjust image proportionally
            coverView.frame = CGRectMake(0, 0, scrollView.frame.size.width, self.coverViewHeight - scrollOffset)
        } else {
            // We're scrolling up, return to normal behavior
            coverView.frame = CGRectMake(0, -scrollOffset, scrollView.frame.size.width, self.coverViewHeight)
        }
    }
    
    // MARK: Cover View
    class CoverView: UIView {
        class PreviewItem: NSObject, QLPreviewItem {
            @objc var previewItemURL: NSURL
            @objc var previewItemTitle: String?
            
            init(URL: NSURL, title: String) {
                self.previewItemURL = URL
                self.previewItemTitle = title
            }
        }
        
        var currentImage: UIImage? {
            get {
                return self.coverImageView?.image
            }
        }
        
        weak var delegate: NewsViewController?
        private weak var coverImageView: RemoteImageView?
        private weak var shadowImageView: UIImageView?
        private weak var button: UIButton?
        
        private var imageURLs: Array<NSURL> = []
        private var currentIndex: Int = 0
        private var imageCache: NSCache
        
        override init(frame: CGRect) {
            self.imageCache = NSCache()
            super.init(frame: frame)
            self.backgroundColor = UIColor(white: 0.2, alpha: 1)
            
            let coverImageView = RemoteImageView(frame: CGRectZero)
            coverImageView.imageCache = self.imageCache
            coverImageView.clipsToBounds = true
            coverImageView.contentMode = .ScaleAspectFill
            self.addSubview(coverImageView)
            self.coverImageView = coverImageView
            
            let shadowImageView = UIImageView()
            shadowImageView.image = UIImage(named: "coverShadow")?.resizableImageWithCapInsets(UIEdgeInsetsMake(8, 8, 8, 8))
            self.addSubview(shadowImageView)
            self.shadowImageView = shadowImageView
            
            let button = UIButton(type: .Custom)
            button.addTarget(self, action: "buttonPressed", forControlEvents: .TouchUpInside)
            self.addSubview(button)
            self.button = button
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            self.coverImageView?.frame = self.bounds
            self.shadowImageView?.frame = self.bounds
            self.button?.frame = self.bounds
        }
        
        func update(posts: Array<SocialPost>) {
            var imageURLs = Array<NSURL>()
            for post in posts {
                imageURLs.appendContentsOf(post.images)
            }
            
            if self.imageURLs != imageURLs {
                self.dynamicType.cancelPreviousPerformRequestsWithTarget(self, selector: "transition", object: nil)
                self.imageURLs = imageURLs
                self.currentIndex = 0
                
                if imageURLs.count > 0 {
                    self.transition()
                }
            }
        }
        
        func transition() {
            self.coverImageView?.updateImage(self.imageURLs[self.currentIndex], transition: true, completionHandler: { () -> Void in
                self.currentIndex += 1
                if self.currentIndex >= self.imageURLs.count {
                    self.currentIndex = 0
                }
                
                self.performSelector("transition", withObject: nil, afterDelay: 5)
            })
        }
        
        func buttonPressed() {
            self.delegate?.coverViewPressed()
        }
    }
    
    class PreviewController: QLPreviewController {
        override func preferredStatusBarStyle() -> UIStatusBarStyle {
            return .LightContent
        }
    }
}
