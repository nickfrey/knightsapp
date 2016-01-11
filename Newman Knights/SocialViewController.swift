//
//  SocialViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class SocialViewController: FetchedViewController, UITableViewDataSource, UITableViewDelegate {
    private weak var tableView: UITableView?
    private var refreshControl: UIRefreshControl?
    private var posts: Array<SocialPost> = []
    private let imageCache: NSCache
    private let cellIdentifier = "Cell"
    
    init() {
        self.imageCache = NSCache()
        super.init(nibName: nil, bundle: nil)
        self.title = "Social"
        self.tabBarItem.image = UIImage(named: "tabSocial")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.hidden = true
        tableView.estimatedRowHeight = 50
        tableView.registerClass(Cell.self, forCellReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(tableView)
        self.tableView = tableView
        
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "fetch", forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
        tableView.sendSubviewToBack(refreshControl)
        self.refreshControl = refreshControl
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView?.frame = self.view.bounds
        self.tableView?.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetch()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            self.tableView?.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
    }
    
    override func fetch() {
        super.fetch()
        
        DataSource.fetchSocialPosts(35) { (posts, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.refreshControl?.endRefreshing()
                
                guard let posts = posts where error == nil else {
                    self.tableView?.hidden = true
                    let fallbackError = NSError(
                        domain: NSURLErrorDomain,
                        code: NSURLErrorUnknown,
                        userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
                    )
                    return self.fetchFinished(error == nil ? fallbackError : error)
                }
                
                self.posts = posts
                self.fetchFinished(nil)
                self.tableView?.reloadData()
                self.tableView?.hidden = false
            })
        }
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Cell.heightForPost(self.posts[indexPath.row], contentWidth: tableView.bounds.size.width)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath) as! Cell
        cell.imageCache = self.imageCache
        cell.post = self.posts[indexPath.row]
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.posts[indexPath.row].openInExternalApplication()
    }
    
    // MARK: Table View Cell
    class Cell: UITableViewCell {
        private let avatarImageView: RemoteImageView
        private let displayNameLabel: UILabel
        private let contentLabel: UILabel
        private let dateLabel: UILabel
        
        var post: SocialPost? {
            didSet {
                guard let post = post else {
                    self.avatarImageView.image = nil
                    self.displayNameLabel.text = nil
                    self.contentLabel.text = nil
                    self.dateLabel.text = nil
                    return
                }
                
                if let displayName = post.author.displayName {
                    self.displayNameLabel.text = displayName
                } else if let username = post.author.username {
                    self.displayNameLabel.text = username
                } else {
                    self.displayNameLabel.text = ""
                }
                
                if let avatarURL = post.author.avatarURL {
                    self.avatarImageView.updateImage(avatarURL, transition: false, completionHandler: nil)
                } else {
                    self.avatarImageView.updateImage(nil, transition: false, completionHandler: nil)
                }
                
                self.contentLabel.text = post.content
                self.dateLabel.text = MHPrettyDate.prettyDateFromDate(post.creationDate, withFormat: MHPrettyDateLongRelativeTime)
            }
        }
        
        var imageCache: NSCache? {
            get {
                return self.avatarImageView.imageCache
            }
            set {
                self.avatarImageView.imageCache = imageCache
            }
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            self.avatarImageView = RemoteImageView(frame: CGRectZero)
            self.displayNameLabel = UILabel()
            self.contentLabel = UILabel()
            self.dateLabel = UILabel()
            
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0)
            
            self.avatarImageView.layer.cornerRadius = 6
            self.contentView.addSubview(self.avatarImageView)
            
            self.displayNameLabel.font = self.dynamicType.displayNameFont()
            self.contentView.addSubview(self.displayNameLabel)
            
            self.contentLabel.numberOfLines = 0
            self.contentLabel.font = self.dynamicType.contentFont()
            self.contentView.addSubview(self.contentLabel)
            
            self.dateLabel.font = self.dynamicType.contentFont()
            self.dateLabel.textColor = UIColor(white: 0.5, alpha: 1)
            self.contentView.addSubview(self.dateLabel)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            self.avatarImageView.image = nil
            self.displayNameLabel.text = nil
            self.contentLabel.text = nil
            self.dateLabel.text = nil
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let margin = self.dynamicType.contentInsets()
            let avatarSize = self.dynamicType.avatarSize()
            let width = CGRectGetWidth(self.bounds)
            let labelWidth = (width - margin.left - margin.right)
            let dateFittingSize = self.dateLabel.sizeThatFits(CGSizeMake(labelWidth, CGFloat.max))
            let dateFrame = CGRectMake(width - dateFittingSize.width - margin.right, margin.top, dateFittingSize.width, dateFittingSize.height)
            let displayNameFittingSize = self.displayNameLabel.sizeThatFits(CGSizeMake(labelWidth - CGRectGetWidth(dateFrame) - 20, CGFloat.max))
            let displayNameFrame = CGRectMake(margin.left, margin.top, labelWidth - CGRectGetWidth(dateFrame) - 20, displayNameFittingSize.height)
            let contentFittingSize = self.contentLabel.sizeThatFits(CGSizeMake(labelWidth, CGFloat.max))
            let contentFrame = CGRectMake(margin.left, CGRectGetMaxY(displayNameFrame) + 2, labelWidth, contentFittingSize.height)
            
            self.avatarImageView.frame = CGRectMake(10, margin.top, avatarSize.width, avatarSize.height)
            self.displayNameLabel.frame = displayNameFrame
            self.contentLabel.frame = contentFrame
            self.dateLabel.frame = dateFrame
        }
        
        // MARK: Class methods
        class func contentInsets() -> UIEdgeInsets {
            return UIEdgeInsetsMake(10, 70, 10, 15)
        }
        
        class func avatarSize() -> CGSize {
            return CGSizeMake(50, 50)
        }
        
        class func displayNameFont() -> UIFont {
            return UIFont.boldSystemFontOfSize(15)
        }
        
        class func contentFont() -> UIFont {
            return UIFont.systemFontOfSize(14)
        }
        
        class func heightForPost(post: SocialPost, contentWidth: CGFloat) -> CGFloat {
            let margins = self.contentInsets()
            let availableWidth = (contentWidth - margins.left - margins.right)
            var totalHeight = (margins.top + margins.bottom)
            
            totalHeight += post.content.boundingRectWithSize(
                CGSizeMake(availableWidth, CGFloat.max),
                options: [.UsesLineFragmentOrigin],
                attributes: [NSFontAttributeName: self.contentFont()],
                context: nil
            ).height
            
            if let displayName = post.author.displayName {
                totalHeight += (displayName.boundingRectWithSize(
                    CGSizeMake(availableWidth, CGFloat.max),
                    options: [.UsesLineFragmentOrigin],
                    attributes: [NSFontAttributeName: self.displayNameFont()],
                    context: nil
                ).height + 2)
            } else if let username = post.author.username {
                totalHeight += (username.boundingRectWithSize(
                    CGSizeMake(availableWidth, CGFloat.max),
                    options: [.UsesLineFragmentOrigin],
                    attributes: [NSFontAttributeName: self.displayNameFont()],
                    context: nil
                ).height + 2)
            }
            
            return max(margins.top + self.avatarSize().height + margins.bottom, totalHeight)
        }
    }
}
