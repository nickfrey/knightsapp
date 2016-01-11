//
//  ContactViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit
import MapKit

class ContactViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate {
    private let address: String
    private let phoneNumber: String
    private let location: CLLocationCoordinate2D
    
    private weak var mapView: MKMapView?
    private weak var tableView: UITableView?
    private var annotation: MKPointAnnotation?
    private let cellIdentifier = "Cell"
    
    init() {
        self.address = AppConfiguration.School.Address
        self.phoneNumber = AppConfiguration.School.PhoneNumber
        self.location =  CLLocationCoordinate2DMake(AppConfiguration.School.Coordinate.Latitude, AppConfiguration.School.Coordinate.Longitude)
        super.init(nibName: nil, bundle: nil)
        self.title = "Contact"
        self.tabBarItem.image = UIImage(named: "tabContact")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.edgesForExtendedLayout = .None
        self.extendedLayoutIncludesOpaqueBars = false
        
        let mapView = MKMapView()
        mapView.mapType = .Hybrid
        mapView.delegate = self
        self.view.addSubview(mapView)
        self.mapView = mapView
        
        let annotation = MKPointAnnotation()
        annotation.title = AppConfiguration.School.Title
        annotation.subtitle = AppConfiguration.School.Subtitle
        annotation.coordinate = self.location
        mapView.addAnnotation(annotation)
        self.annotation = annotation
        
        let tableView = UITableView(frame: CGRectZero, style: .Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(tableView)
        self.tableView = tableView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let viewWidth = CGRectGetWidth(self.view.bounds)
        let viewHeight = CGRectGetHeight(self.view.bounds)
        let mapViewFrame = CGRectMake(0, 0, viewWidth, (self.traitCollection.horizontalSizeClass == .Regular ? 325 : 150))
        
        self.mapView?.frame = mapViewFrame
        self.tableView?.frame = CGRectMake(0, CGRectGetMaxY(mapViewFrame), viewWidth, viewHeight - CGRectGetMaxY(mapViewFrame))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            self.tableView?.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
        
        self.mapView?.region = MKCoordinateRegionMake(self.location, MKCoordinateSpanMake(0.0005, 0.0005))
        self.mapView?.centerCoordinate = self.location
    }
    
    // MARK: MKMapViewDelegate
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "Pin"
        if let reusedAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) {
            return reusedAnnotationView
        } else {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.canShowCallout = true
            annotationView.animatesDrop = true
            annotationView.pinColor = .Green
            return annotationView
        }
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0 ? 2 : 3)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 1 {
            return 65
        } else {
            return 44
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.numberOfLines = 1
        cell.accessoryType = .None
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = self.phoneNumber
                cell.imageView?.image = UIImage(named: "contactIconPhone")
            } else if indexPath.row == 1 {
                cell.textLabel?.text = self.address
                cell.textLabel?.numberOfLines = 2
                cell.imageView?.image = UIImage(named: "contactIconLocation")
            }
        } else {
            cell.accessoryType = .DisclosureIndicator
            cell.imageView?.image = UIImage(named: "contactIconMail")
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Administration"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Office"
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Teachers"
            }
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            if indexPath.row == 0 {
                let phoneURL = NSURL(string: "tel://" + self.phoneNumber.stringByRemovingPercentEncoding!)!
                
                if UIApplication.sharedApplication().canOpenURL(phoneURL) {
                    UIApplication.sharedApplication().openURL(NSURL(string: "tel://" + self.phoneNumber.stringByRemovingPercentEncoding!)!)
                } else {
                    let alertController = UIAlertController(
                        title: "Cannot Place Call",
                        message: "This device does not support placing phone calls.",
                        preferredStyle: .Alert
                    )
                    alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            } else {
                let placemark = MKPlacemark(coordinate: self.location, addressDictionary: nil)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = AppConfiguration.School.Title
                mapItem.openInMapsWithLaunchOptions(nil)
            }
        } else if indexPath.section == 1 {
            var directory: Contact.Directory = .Faculty
            
            if indexPath.row == 0 {
                directory = .Administration
            } else if indexPath.row == 1 {
                directory = .Office
            }
            
            self.navigationController?.pushViewController(DirectoryViewController(directory: directory), animated: true)
        }
    }
}
