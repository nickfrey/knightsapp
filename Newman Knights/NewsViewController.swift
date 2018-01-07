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
    fileprivate weak var tableView: UITableView?
    fileprivate weak var coverView: CoverView?
    fileprivate var coverViewPreviewItem: CoverView.PreviewItem?
    fileprivate var coverViewHeight: CGFloat = 150
    fileprivate var socialPosts: Array<SocialPost> = []
    fileprivate var todayEvents: Array<Event> = []
    fileprivate var tomorrowEvents: Array<Event> = []
    fileprivate var imageCache: NSCache<AnyObject, AnyObject>
    fileprivate let eventCellIdentifier = "Event"
    fileprivate let socialCellIdentifier = "Social"
    fileprivate let emptyCellIdentifier = "Empty"
    
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
        
        if self.traitCollection.horizontalSizeClass == .regular {
            self.coverViewHeight = 325
        }
        
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = self.view.backgroundColor
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: self.coverViewHeight))
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.coverViewHeight, 0, 0, 0)
        tableView.estimatedRowHeight = 50
        tableView.alwaysBounceVertical = true
        tableView.register(SocialViewController.Cell.self, forCellReuseIdentifier: self.socialCellIdentifier)
        tableView.register(CalendarDayViewController.EventCell.self, forCellReuseIdentifier: self.eventCellIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.emptyCellIdentifier)
        self.view.addSubview(tableView)
        self.tableView = tableView
        
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        let coverView = CoverView()
        coverView.isHidden = true
        coverView.delegate = self
        self.view.addSubview(coverView)
        self.coverView = coverView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.coverView?.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.coverViewHeight)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetch), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func fetch() {
        super.fetch()
        DataSource.fetchSocialPosts(10) { (posts, error) -> Void in
            guard let posts = posts, error == nil else {
                return DispatchQueue.main.async(execute: {
                    self.fetchFinished(error)
                })
            }
            
            _ = EventCalendar.fetchEvents(Date(), completionHandler: { (todayEvents, error) -> Void in
                guard let todayEvents = todayEvents, error == nil else {
                    return DispatchQueue.main.async(execute: {
                        self.fetchFinished(error)
                    })
                }
                
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                _ = EventCalendar.fetchEvents(tomorrowDate!, completionHandler: { (tomorrowEvents, error) -> Void in
                    DispatchQueue.main.async(execute: {
                        guard let tomorrowEvents = tomorrowEvents, error == nil else {
                            return self.fetchFinished(error)
                        }
                        
                        self.socialPosts = posts
                        self.todayEvents = todayEvents
                        self.tomorrowEvents = tomorrowEvents
                        self.fetchFinished(nil)
                        
                        self.coverView?.update(posts)
                        self.tableView?.reloadData()
                        self.coverView?.isHidden = false
                        self.tableView?.isHidden = false
                    })
                })
            })
        }
    }
    
    func coverViewPressed() {
        guard let coverView = self.coverView else { return }
        guard let coverImage = coverView.currentImage else { return }
        
        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let imageURL = temporaryURL.appendingPathComponent("photo").appendingPathExtension("jpg")
        
        do {
            try UIImageJPEGRepresentation(coverImage, 1)?.write(to: imageURL, options: [])
            self.coverViewPreviewItem = CoverView.PreviewItem(URL: imageURL, title: "Recently Tweeted")
            
            let viewController = PreviewController()
            viewController.dataSource = self
            self.present(viewController, animated: true, completion: nil)
        } catch _ {
        }
    }
    
    // MARK: QLPreviewControllerDelegate
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.coverViewPreviewItem!
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return (self.coverViewPreviewItem == nil ? 0 : 1)
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && self.socialPosts.count > 0 {
            return SocialViewController.Cell.heightForPost(self.socialPosts[indexPath.row], contentWidth: tableView.bounds.size.width)
        } else {
            return 55
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if self.socialPosts.count == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: self.emptyCellIdentifier, for: indexPath)
                cell.textLabel?.text = "No tweets to show."
                cell.selectionStyle = .none
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: self.socialCellIdentifier, for: indexPath) as! SocialViewController.Cell
            cell.imageCache = self.imageCache
            cell.post = self.socialPosts[indexPath.row]
            return cell
        } else {
            let events = (indexPath.section == 1 ? self.todayEvents : self.tomorrowEvents)
            if events.count == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: self.emptyCellIdentifier, for: indexPath)
                cell.textLabel?.text = "No events to show."
                cell.selectionStyle = .none
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: self.eventCellIdentifier, for: indexPath) as! CalendarDayViewController.EventCell
            cell.event = events[indexPath.row]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if self.socialPosts.count > 0 {
                tableView.deselectRow(at: indexPath, animated: true)
                self.socialPosts[indexPath.row].openInExternalApplication()
            }
        } else {
            let events = (indexPath.section == 1 ? self.todayEvents : self.tomorrowEvents)
            if events.count > 0 {
                let viewController = CalendarEventViewController(event: events[indexPath.row])
                
                if self.traitCollection.horizontalSizeClass == .regular {
                    tableView.deselectRow(at: indexPath, animated: true)
                    
                    let cell = tableView.cellForRow(at: indexPath)
                    let navigationController = UINavigationController(rootViewController: viewController)
                    navigationController.modalPresentationStyle = .popover
                    navigationController.popoverPresentationController?.sourceView = cell
                    navigationController.popoverPresentationController?.sourceRect = cell!.bounds
                    self.present(navigationController, animated: true, completion: nil)
                } else {
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let coverView = self.coverView else { return }
        let scrollOffset = scrollView.contentOffset.y
        
        if scrollOffset < 0 {
            // Adjust image proportionally
            coverView.frame = CGRect(x: 0, y: 0, width: scrollView.frame.size.width, height: self.coverViewHeight - scrollOffset)
        } else {
            // We're scrolling up, return to normal behavior
            coverView.frame = CGRect(x: 0, y: -scrollOffset, width: scrollView.frame.size.width, height: self.coverViewHeight)
        }
    }
    
    // MARK: Cover View
    class CoverView: UIView {
        class PreviewItem: NSObject, QLPreviewItem {
            @objc var previewItemURL: URL?
            @objc var previewItemTitle: String?
            
            init(URL: URL, title: String) {
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
        fileprivate weak var coverImageView: RemoteImageView?
        fileprivate weak var shadowImageView: UIImageView?
        fileprivate weak var button: UIButton?
        
        fileprivate var imageURLs: Array<URL> = []
        fileprivate var currentIndex: Int = 0
        fileprivate var imageCache: NSCache<AnyObject, AnyObject>
        
        override init(frame: CGRect) {
            self.imageCache = NSCache()
            super.init(frame: frame)
            self.backgroundColor = UIColor(white: 0.2, alpha: 1)
            
            let coverImageView = RemoteImageView(frame: .zero)
            coverImageView.imageCache = self.imageCache
            coverImageView.clipsToBounds = true
            coverImageView.contentMode = .scaleAspectFill
            self.addSubview(coverImageView)
            self.coverImageView = coverImageView
            
            let shadowImageView = UIImageView()
            shadowImageView.image = UIImage(named: "coverShadow")?.resizableImage(withCapInsets: UIEdgeInsetsMake(8, 8, 8, 8))
            self.addSubview(shadowImageView)
            self.shadowImageView = shadowImageView
            
            let button = UIButton(type: .custom)
            button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
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
        
        func update(_ posts: Array<SocialPost>) {
            var imageURLs = Array<URL>()
            for post in posts {
                imageURLs.append(contentsOf: post.images)
            }
            
            if self.imageURLs != imageURLs {
                type(of: self).cancelPreviousPerformRequests(withTarget: self, selector: #selector(transition), object: nil)
                self.imageURLs = imageURLs
                self.currentIndex = 0
                
                if imageURLs.count > 0 {
                    self.transition()
                }
            }
        }
        
        @objc func transition() {
            self.coverImageView?.updateImage(self.imageURLs[self.currentIndex], transition: true, completionHandler: { () -> Void in
                self.currentIndex += 1
                if self.currentIndex >= self.imageURLs.count {
                    self.currentIndex = 0
                }
                
                self.perform(#selector(self.transition), with: nil, afterDelay: 5)
            })
        }
        
        func buttonPressed() {
            self.delegate?.coverViewPressed()
        }
    }
    
    class PreviewController: QLPreviewController {
        override var preferredStatusBarStyle : UIStatusBarStyle {
            return .lightContent
        }
    }
}
