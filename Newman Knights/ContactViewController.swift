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
    fileprivate let address: String
    fileprivate let phoneNumber: String
    fileprivate let location: CLLocationCoordinate2D
    
    fileprivate weak var mapView: MKMapView?
    fileprivate weak var tableView: UITableView?
    fileprivate var annotation: MKPointAnnotation?
    fileprivate let cellIdentifier = "Cell"
    
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
        
        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars = false
        
        let mapView = MKMapView()
        mapView.mapType = .hybrid
        mapView.delegate = self
        self.view.addSubview(mapView)
        self.mapView = mapView
        
        let annotation = MKPointAnnotation()
        annotation.title = AppConfiguration.School.Title
        annotation.subtitle = AppConfiguration.School.Subtitle
        annotation.coordinate = self.location
        mapView.addAnnotation(annotation)
        self.annotation = annotation
        
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(tableView)
        self.tableView = tableView
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let viewWidth = self.view.bounds.width
        let viewHeight = self.view.bounds.height
        let mapViewFrame = CGRect(x: 0, y: 0, width: viewWidth, height: (self.traitCollection.horizontalSizeClass == .regular ? 325 : 150))
        
        self.mapView?.frame = mapViewFrame
        self.tableView?.frame = CGRect(x: 0, y: mapViewFrame.maxY, width: viewWidth, height: viewHeight - mapViewFrame.maxY)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView?.indexPathForSelectedRow {
            self.tableView?.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        self.mapView?.region = MKCoordinateRegionMake(self.location, MKCoordinateSpanMake(0.0005, 0.0005))
        self.mapView?.centerCoordinate = self.location
    }
    
    // MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "Pin"
        if let reusedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            return reusedAnnotationView
        } else {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.canShowCallout = true
            annotationView.animatesDrop = true
            annotationView.pinColor = .green
            return annotationView
        }
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0 ? 2 : 3)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 1 {
            return 65
        } else {
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        cell.textLabel?.numberOfLines = 1
        cell.accessoryType = .none
        
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
            cell.accessoryType = .disclosureIndicator
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            
            if indexPath.row == 0 {
                let phoneURL = URL(string: "tel://" + self.phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())!
                
                if UIApplication.shared.canOpenURL(phoneURL) {
                    UIApplication.shared.openURL(phoneURL)
                } else {
                    let alertController = UIAlertController(
                        title: "Cannot Place Call",
                        message: "This device does not support placing phone calls.",
                        preferredStyle: .alert
                    )
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                let placemark = MKPlacemark(coordinate: self.location, addressDictionary: nil)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = AppConfiguration.School.Title
                mapItem.openInMaps(launchOptions: nil)
            }
        } else if indexPath.section == 1 {
            var directory: Contact.Directory = .faculty
            
            if indexPath.row == 0 {
                directory = .administration
            } else if indexPath.row == 1 {
                directory = .office
            }
            
            self.navigationController?.pushViewController(DirectoryViewController(directory: directory), animated: true)
        }
    }
}
