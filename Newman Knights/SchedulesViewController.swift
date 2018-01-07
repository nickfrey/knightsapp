//
//  SchedulesViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class SchedulesViewController: FetchedViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    fileprivate var schedules: Array<Schedule> = []
    fileprivate let cellIdentifier = "Cell"
    fileprivate weak var tableView: UITableView?
    fileprivate weak var collectionView: UICollectionView?
    fileprivate weak var collectionViewLayout: UICollectionViewFlowLayout?
    
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
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(fetch))
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.itemSize = CGSize(width: 250, height: 250)
        collectionViewLayout.minimumInteritemSpacing = 50
        collectionViewLayout.minimumLineSpacing = 50
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(70, 70, 70, 70)
        self.collectionViewLayout = collectionViewLayout
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isHidden = true
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = self.view.backgroundColor
        collectionView.register(Cell.self, forCellWithReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(collectionView)
        self.view.sendSubview(toBack: collectionView)
        self.collectionView = collectionView
        
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true
        tableView.backgroundColor = self.view.backgroundColor
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(tableView)
        self.view.sendSubview(toBack: tableView)
        self.tableView = tableView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.tableView?.frame = self.view.bounds
        self.collectionView?.frame = self.view.bounds
        
        self.tableView?.isHidden = (self.fetching || self.traitCollection.horizontalSizeClass == .regular)
        self.collectionView?.isHidden = (self.fetching || self.traitCollection.horizontalSizeClass != .regular)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            self.tableView?.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        if let selectedIndexPaths = self.collectionView?.indexPathsForSelectedItems {
            for indexPath in selectedIndexPaths {
                self.collectionView?.deselectItem(at: indexPath, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetch()
    }
    
    @objc override func fetch() {
        self.tableView?.isHidden = true
        self.collectionView?.isHidden = true
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        super.fetch()
        
        DataSource.fetchSchedules { (schedules, error) -> Void in
            DispatchQueue.main.async(execute: {
                guard let schedules = schedules, error == nil else {
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
                
                self.tableView?.isHidden = (self.traitCollection.horizontalSizeClass == .regular)
                self.collectionView?.isHidden = (self.traitCollection.horizontalSizeClass != .regular)
            })
        }
    }
    
    override func fetchFinished(_ error: Error?) {
        super.fetchFinished(error)
        self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func selectScheduleAtIndex(_ index: Int) {
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.schedules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = self.schedules[indexPath.row].title
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectScheduleAtIndex(indexPath.row)
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.schedules.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier, for: indexPath) as! Cell
        cell.title = self.schedules[indexPath.item].title
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectScheduleAtIndex(indexPath.item)
    }
    
    // MARK: Collection View Cell
    class Cell: UICollectionViewCell {
        fileprivate weak var titleLabel: UILabel?
        
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
            
            self.backgroundColor = .white
            self.layer.borderColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1).cgColor
            self.layer.borderWidth = 1
            self.layer.cornerRadius = 8
            self.layer.masksToBounds = true
            
            self.selectedBackgroundView = UIView()
            self.selectedBackgroundView!.backgroundColor = UIColor(white: 217/255, alpha: 1)
            
            let titleLabel = UILabel()
            titleLabel.font = UIFont.systemFont(ofSize: 18)
            titleLabel.textAlignment = .center
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
