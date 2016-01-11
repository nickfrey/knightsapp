//
//  SchedulesViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class SchedulesViewController: FetchedViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    private var schedules: Array<Schedule> = []
    private let cellIdentifier = "Cell"
    private weak var tableView: UITableView?
    private weak var collectionView: UICollectionView?
    private weak var collectionViewLayout: UICollectionViewFlowLayout?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.title = "Schedules"
        self.tabBarItem.image = UIImage(named: "tabSchedule")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "fetch")
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.itemSize = CGSizeMake(250, 250)
        collectionViewLayout.minimumInteritemSpacing = 50
        collectionViewLayout.minimumLineSpacing = 50
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(70, 70, 70, 70)
        self.collectionViewLayout = collectionViewLayout
        
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.hidden = true
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = self.view.backgroundColor
        collectionView.registerClass(Cell.self, forCellWithReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(collectionView)
        self.view.sendSubviewToBack(collectionView)
        self.collectionView = collectionView
        
        let tableView = UITableView(frame: CGRectZero, style: .Grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.hidden = true
        tableView.backgroundColor = self.view.backgroundColor
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(tableView)
        self.view.sendSubviewToBack(tableView)
        self.tableView = tableView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.tableView?.frame = self.view.bounds
        self.collectionView?.frame = self.view.bounds
        
        self.tableView?.hidden = (self.fetching || self.traitCollection.horizontalSizeClass == .Regular)
        self.collectionView?.hidden = (self.fetching || self.traitCollection.horizontalSizeClass != .Regular)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            self.tableView?.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
        
        if let selectedIndexPaths = self.collectionView?.indexPathsForSelectedItems() {
            for indexPath in selectedIndexPaths {
                self.collectionView?.deselectItemAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetch()
    }
    
    override func fetch() {
        self.tableView?.hidden = true
        self.collectionView?.hidden = true
        self.navigationItem.rightBarButtonItem?.enabled = false
        super.fetch()
        
        DataSource.fetchSchedules { (schedules, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                guard let schedules = schedules where error == nil else {
                    let fallbackError = NSError(
                        domain: NSURLErrorDomain,
                        code: NSURLErrorUnknown,
                        userInfo: [NSLocalizedDescriptionKey: "An unknown error occurred."]
                    )
                    return self.fetchFinished(error == nil ? fallbackError : error)
                }
                
                self.schedules = schedules
                self.fetchFinished(nil)
                
                self.tableView?.reloadData()
                self.collectionView?.reloadData()
                
                self.tableView?.hidden = (self.traitCollection.horizontalSizeClass == .Regular)
                self.collectionView?.hidden = (self.traitCollection.horizontalSizeClass != .Regular)
            })
        }
    }
    
    override func fetchFinished(error: NSError?) {
        super.fetchFinished(error)
        self.navigationItem.rightBarButtonItem?.enabled = true
    }
    
    func selectScheduleAtIndex(index: Int) {
        let schedule = self.schedules[index]
        var viewController: UIViewController
        
        if let documentID = schedule.documentID {
            viewController = DocumentViewController(identifier: documentID)
        } else if let URL = schedule.URL {
            viewController = WebViewController(URL: URL)
        } else {
            return
        }
        
        viewController.title = schedule.title
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.schedules.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath)
        cell.accessoryType = .DisclosureIndicator
        cell.textLabel?.text = self.schedules[indexPath.row].title
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectScheduleAtIndex(indexPath.row)
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.schedules.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.cellIdentifier, forIndexPath: indexPath) as! Cell
        cell.title = self.schedules[indexPath.item].title
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectScheduleAtIndex(indexPath.item)
    }
    
    // MARK: Collection View Cell
    class Cell: UICollectionViewCell {
        private weak var titleLabel: UILabel?
        
        var title: String? {
            get {
                return self.titleLabel?.text
            }
            set {
                self.titleLabel?.text = title
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.backgroundColor = UIColor.whiteColor()
            self.layer.borderColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1).CGColor
            self.layer.borderWidth = 1
            self.layer.cornerRadius = 8
            self.layer.masksToBounds = true
            
            self.selectedBackgroundView = UIView()
            self.selectedBackgroundView!.backgroundColor = UIColor(white: 217/255, alpha: 1)
            
            let titleLabel = UILabel()
            titleLabel.font = UIFont.systemFontOfSize(18)
            titleLabel.textAlignment = .Center
            titleLabel.numberOfLines = 0
            self.contentView.addSubview(titleLabel)
            self.titleLabel = titleLabel
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            self.titleLabel?.frame = self.bounds
        }
    }
}
