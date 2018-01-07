//
//  CalendarEventViewController.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/24/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

class CalendarEventViewController: UITableViewController {
    let event: Event
    fileprivate let detailsCellIdentifier = "Details"
    fileprivate let locationCellIdentifier = "Location"
    fileprivate let opponentsCellIdentifier = "Opponents"
    
    init(event: Event) {
        self.event = event
        super.init(style: .grouped)
        self.title = "Event Details"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(sharePressed))
        self.tableView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
        self.tableView.separatorColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1)
        self.tableView.register(DetailsCell.self, forCellReuseIdentifier: self.detailsCellIdentifier)
        self.tableView.register(DetailsCell.self, forCellReuseIdentifier: self.opponentsCellIdentifier)
        self.tableView.register(LocationCell.self, forCellReuseIdentifier: self.locationCellIdentifier)
    }
    
    @objc func sharePressed() {
        if let identifier = self.event.identifier {
            let shareURL = URL(string: "http://www.northiowaconference.org/g5-bin/client.cgi?cwellOnly=1&G5statusflag=view_note&schoolname=&school_id=5&G5button=13&G5genie=97&view_id=" + identifier)!
            let viewController = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 1
        
        if let location = self.event.location, location.count > 0 {
            rows += 1
        }
        
        if self.event.opponents.count > 0 {
            rows += 1
        }
        
        return rows
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            let attributedString = DetailsCell.attributedStringFromEvent(self.event)
            return DetailsCell.heightWithAttributedString(attributedString, contentWidth: tableView.bounds.size.width - 20)
        } else if indexPath.row == 1 && self.event.location != nil {
            return 50
        } else {
            let attributedString = DetailsCell.attributedStringFromOpponents(self.event.opponents)
            return DetailsCell.heightWithAttributedString(attributedString, contentWidth: tableView.bounds.size.width - 20)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: self.detailsCellIdentifier, for: indexPath) as! DetailsCell
            cell.textLabel?.attributedText = DetailsCell.attributedStringFromEvent(self.event)
            return cell
        } else if indexPath.row == 1 && self.event.location != nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: self.locationCellIdentifier, for: indexPath) as! LocationCell
            cell.textLabel?.text = "Location"
            cell.detailTextLabel?.text = self.event.location!
            
            if self.event.location != "TBA" {
                cell.accessoryType = .disclosureIndicator
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: self.opponentsCellIdentifier, for: indexPath) as! DetailsCell
            cell.textLabel?.attributedText = DetailsCell.attributedStringFromOpponents(self.event.opponents)
            return cell
        }
    }
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 1 {
            if let location = self.event.location, location.count > 0 && location != "TBA" {
                UIApplication.shared.openURL(URL(string: "https://maps.apple.com/maps?q=" + location.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!)
            }
        }
    }
    
    // MARK: Cells
    class DetailsCell: UITableViewCell {
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.selectionStyle = .none
            self.textLabel?.numberOfLines = 0
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        fileprivate class func dateStringForEvent(_ event: Event) -> String? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            
            var dateString = ""
            
            if let startDate = event.startDate {
                dateString = dateFormatter.string(from: startDate)
                
                let startTime = timeFormatter.string(from: startDate)
                if startTime != "12:00 AM" {
                    dateString += "\n" + startTime
                }
                
                if let endDate = event.endDate {
                    let endTime = timeFormatter.string(from: endDate)
                    if endTime != "12:00 AM" {
                        dateString += " to " + endTime
                    }
                }
            } else if let endDate = event.endDate {
                let endTime = timeFormatter.string(from: endDate)
                if endTime != "12:00 AM" {
                    dateString += "Ends at " + endTime
                }
            }
            
            if let status = event.status, status.count > 0 {
                dateString += (dateString.count > 0 ? "\n" : "") + status
            }
            
            return (dateString.count > 0 ? dateString : nil)
        }
        
        class func attributedStringFromEvent(_ event: Event) -> NSAttributedString {
            let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.lineSpacing = 5
            
            let attributedString = NSMutableAttributedString()
            
            if let title = event.computedTitle() {
                attributedString.append(
                    NSAttributedString(
                        string: title,
                        attributes: [
                            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 20),
                            NSAttributedStringKey.paragraphStyle: paragraphStyle
                        ]
                    )
                )
            }
            
            if let date = self.dateStringForEvent(event) {
                attributedString.append(
                    NSAttributedString(
                        string: (attributedString.length > 0 ? "\n" : "") + date,
                        attributes: [
                            NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .subheadline),
                            NSAttributedStringKey.foregroundColor: UIColor(white: 0.5, alpha: 1)
                        ]
                    )
                )
            }
            
            if let comment = event.details {
                attributedString.append(
                    NSAttributedString(
                        string: (attributedString.length > 0 ? "\n" : "") + comment,
                        attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]
                    )
                )
            }
            
            return attributedString
        }
        
        class func attributedStringFromOpponents(_ opponents: Array<String>) -> NSAttributedString {
            let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.lineSpacing = 5
            
            let attributedString = NSMutableAttributedString(
                string: "Opponents\n",
                attributes: [
                    NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body),
                    NSAttributedStringKey.paragraphStyle: paragraphStyle
                ]
            )
            
            attributedString.append(
                NSAttributedString(
                    string: opponents.joined(separator: "\n"),
                    attributes: [
                        NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .subheadline),
                        NSAttributedStringKey.foregroundColor: UIColor(white: 0.5, alpha: 1)
                    ]
                )
            )
            
            return attributedString
        }
        
        class func heightWithAttributedString(_ attributedString: NSAttributedString, contentWidth: CGFloat) -> CGFloat {
            return attributedString.boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                context: nil
            ).height + 30
        }
    }
    
    class LocationCell: UITableViewCell {
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
