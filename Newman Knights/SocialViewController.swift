//
//  SocialViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class SocialViewController: FetchedViewController, UITableViewDataSource, UITableViewDelegate {
    fileprivate weak var tableView: UITableView?
    fileprivate var refreshControl: UIRefreshControl?
    fileprivate var posts: Array<SocialPost> = []
    fileprivate let imageCache: NSCache<AnyObject, AnyObject>
    fileprivate let cellIdentifier = "Cell"
    
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
        tableView.isHidden = true
        tableView.estimatedRowHeight = 50
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.register(Cell.self, forCellReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(tableView)
        self.tableView = tableView
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetch), for: .valueChanged)
        tableView.addSubview(refreshControl)
        tableView.sendSubview(toBack: refreshControl)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            self.tableView?.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    @objc override func fetch() {
        super.fetch()
        
        DataSource.fetchSocialPosts(35) { (posts, error) -> Void in
            DispatchQueue.main.async(execute: {
                self.refreshControl?.endRefreshing()
                
                guard let posts = posts, error == nil else {
                    self.tableView?.isHidden = true
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
                self.tableView?.isHidden = false
            })
        }
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Cell.heightForPost(self.posts[indexPath.row], contentWidth: tableView.bounds.size.width)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath) as! Cell
        cell.imageCache = self.imageCache
        cell.post = self.posts[indexPath.row]
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.posts[indexPath.row].openInExternalApplication()
    }
    
    // MARK: Table View Cell
    class Cell: UITableViewCell {
        fileprivate let avatarImageView: RemoteImageView
        fileprivate let displayNameLabel: UILabel
        fileprivate let contentLabel: UILabel
        fileprivate let dateLabel: UILabel
        
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
                self.dateLabel.text = MHPrettyDate.prettyDate(from: post.creationDate, with: MHPrettyDateLongRelativeTime)
            }
        }
        
        var imageCache: NSCache<AnyObject, AnyObject>? {
            get {
                return self.avatarImageView.imageCache
            }
            set {
                self.avatarImageView.imageCache = newValue
            }
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            self.avatarImageView = RemoteImageView(frame: .zero)
            self.displayNameLabel = UILabel()
            self.contentLabel = UILabel()
            self.dateLabel = UILabel()
            
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0)
            
            self.avatarImageView.layer.cornerRadius = 6
            self.contentView.addSubview(self.avatarImageView)
            
            self.displayNameLabel.font = type(of: self).displayNameFont()
            self.contentView.addSubview(self.displayNameLabel)
            
            self.contentLabel.numberOfLines = 0
            self.contentLabel.font = type(of: self).contentFont()
            self.contentView.addSubview(self.contentLabel)
            
            self.dateLabel.font = type(of: self).contentFont()
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
            
            let margin = type(of: self).contentInsets()
            let avatarSize = type(of: self).avatarSize()
            let width = self.bounds.width
            let labelWidth = (width - margin.left - margin.right)
            let dateFittingSize = self.dateLabel.sizeThatFits(CGSize(width: labelWidth, height: .greatestFiniteMagnitude))
            let dateFrame = CGRect(x: width - dateFittingSize.width - margin.right, y: margin.top, width: dateFittingSize.width, height: dateFittingSize.height)
            let displayNameFittingSize = self.displayNameLabel.sizeThatFits(CGSize(width: labelWidth - dateFrame.width - 20, height: .greatestFiniteMagnitude))
            let displayNameFrame = CGRect(x: margin.left, y: margin.top, width: labelWidth - dateFrame.width - 20, height: displayNameFittingSize.height)
            let contentFittingSize = self.contentLabel.sizeThatFits(CGSize(width: labelWidth, height: .greatestFiniteMagnitude))
            let contentFrame = CGRect(x: margin.left, y: displayNameFrame.maxY + 2, width: labelWidth, height: contentFittingSize.height)
            
            self.avatarImageView.frame = CGRect(x: 10, y: margin.top, width: avatarSize.width, height: avatarSize.height)
            self.displayNameLabel.frame = displayNameFrame
            self.contentLabel.frame = contentFrame
            self.dateLabel.frame = dateFrame
        }
        
        // MARK: Class methods
        class func contentInsets() -> UIEdgeInsets {
            return UIEdgeInsetsMake(10, 70, 10, 15)
        }
        
        class func avatarSize() -> CGSize {
            return CGSize(width: 50, height: 50)
        }
        
        class func displayNameFont() -> UIFont {
            return UIFont.boldSystemFont(ofSize: 15)
        }
        
        class func contentFont() -> UIFont {
            return UIFont.systemFont(ofSize: 14)
        }
        
        class func heightForPost(_ post: SocialPost, contentWidth: CGFloat) -> CGFloat {
            let margins = self.contentInsets()
            let availableWidth = (contentWidth - margins.left - margins.right)
            var totalHeight = (margins.top + margins.bottom)
            
            totalHeight += post.content.boundingRect(
                with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: [NSAttributedStringKey.font: self.contentFont()],
                context: nil
            ).height
            
            if let displayName = post.author.displayName {
                totalHeight += (displayName.boundingRect(
                    with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin],
                    attributes: [NSAttributedStringKey.font: self.displayNameFont()],
                    context: nil
                ).height + 2)
            } else if let username = post.author.username {
                totalHeight += (username.boundingRect(
                    with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin],
                    attributes: [NSAttributedStringKey.font: self.displayNameFont()],
                    context: nil
                ).height + 2)
            }
            
            return max(margins.top + self.avatarSize().height + margins.bottom, totalHeight)
        }
    }
}
