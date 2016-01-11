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
    private let detailsCellIdentifier = "Details"
    private let locationCellIdentifier = "Location"
    private let opponentsCellIdentifier = "Opponents"
    
    init(event: Event) {
        self.event = event
        super.init(style: .Grouped)
        self.title = "Event Details"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "sharePressed")
        self.tableView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
        self.tableView.separatorColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1)
        self.tableView.registerClass(DetailsCell.self, forCellReuseIdentifier: self.detailsCellIdentifier)
        self.tableView.registerClass(DetailsCell.self, forCellReuseIdentifier: self.opponentsCellIdentifier)
        self.tableView.registerClass(LocationCell.self, forCellReuseIdentifier: self.locationCellIdentifier)
    }
    
    func sharePressed() {
        if let identifier = self.event.identifier {
            let URL = NSURL(string: "http://www.northiowaconference.org/g5-bin/client.cgi?cwellOnly=1&G5statusflag=view_note&schoolname=&school_id=5&G5button=13&G5genie=97&view_id=" + identifier)!
            let viewController = UIActivityViewController(activityItems: [URL], applicationActivities: nil)
            self.presentViewController(viewController, animated: true, completion: nil)
        }
    }
    
    // MARK: UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 1
        
        if let location = self.event.location where location.characters.count > 0 {
            rows += 1
        }
        
        if self.event.opponents.count > 0 {
            rows += 1
        }
        
        return rows
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(self.detailsCellIdentifier, forIndexPath: indexPath) as! DetailsCell
            cell.textLabel?.attributedText = DetailsCell.attributedStringFromEvent(self.event)
            return cell
        } else if indexPath.row == 1 && self.event.location != nil {
            let cell = tableView.dequeueReusableCellWithIdentifier(self.locationCellIdentifier, forIndexPath: indexPath) as! LocationCell
            cell.textLabel?.text = "Location"
            cell.detailTextLabel?.text = self.event.location!
            
            if self.event.location != "TBA" {
                cell.accessoryType = .DisclosureIndicator
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(self.opponentsCellIdentifier, forIndexPath: indexPath) as! DetailsCell
            cell.textLabel?.attributedText = DetailsCell.attributedStringFromOpponents(self.event.opponents)
            return cell
        }
    }
    
    // MARK: UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.row == 1 {
            if let location = self.event.location where location.characters.count > 0 && location != "TBA" {
                UIApplication.sharedApplication().openURL(NSURL(string: "https://maps.apple.com/maps?q=" + location.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)!)
            }
        }
    }
    
    // MARK: Cells
    class DetailsCell: UITableViewCell {
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.selectionStyle = .None
            self.textLabel?.numberOfLines = 0
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private class func dateStringForEvent(event: Event) -> String? {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .LongStyle
            
            let timeFormatter = NSDateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            
            var dateString = ""
            
            if let startDate = event.startDate {
                dateString = dateFormatter.stringFromDate(startDate)
                
                let startTime = timeFormatter.stringFromDate(startDate)
                if startTime != "12:00 AM" {
                    dateString += "\n" + startTime
                }
                
                if let endDate = event.endDate {
                    let endTime = timeFormatter.stringFromDate(endDate)
                    if endTime != "12:00 AM" {
                        dateString += " to " + endTime
                    }
                }
            } else if let endDate = event.endDate {
                let endTime = timeFormatter.stringFromDate(endDate)
                if endTime != "12:00 AM" {
                    dateString += "Ends at " + endTime
                }
            }
            
            if let status = event.status where status.characters.count > 0 {
                dateString += (dateString.characters.count > 0 ? "\n" : "") + status
            }
            
            return (dateString.characters.count > 0 ? dateString : nil)
        }
        
        class func attributedStringFromEvent(event: Event) -> NSAttributedString {
            let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.lineSpacing = 5
            
            let attributedString = NSMutableAttributedString()
            
            if let title = event.computedTitle() {
                attributedString.appendAttributedString(
                    NSAttributedString(
                        string: title,
                        attributes: [
                            NSFontAttributeName: UIFont.systemFontOfSize(20),
                            NSParagraphStyleAttributeName: paragraphStyle
                        ]
                    )
                )
            }
            
            if let date = self.dateStringForEvent(event) {
                attributedString.appendAttributedString(
                    NSAttributedString(
                        string: (attributedString.length > 0 ? "\n" : "") + date,
                        attributes: [
                            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline),
                            NSForegroundColorAttributeName: UIColor(white: 0.5, alpha: 1)
                        ]
                    )
                )
            }
            
            if let comment = event.details {
                attributedString.appendAttributedString(
                    NSAttributedString(
                        string: (attributedString.length > 0 ? "\n" : "") + comment,
                        attributes: [NSFontAttributeName: UIFont.systemFontOfSize(14)]
                    )
                )
            }
            
            return attributedString
        }
        
        class func attributedStringFromOpponents(opponents: Array<String>) -> NSAttributedString {
            let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.lineSpacing = 5
            
            let attributedString = NSMutableAttributedString(
                string: "Opponents\n",
                attributes: [
                    NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody),
                    NSParagraphStyleAttributeName: paragraphStyle
                ]
            )
            
            attributedString.appendAttributedString(
                NSAttributedString(
                    string: opponents.joinWithSeparator("\n"),
                    attributes: [
                        NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline),
                        NSForegroundColorAttributeName: UIColor(white: 0.5, alpha: 1)
                    ]
                )
            )
            
            return attributedString
        }
        
        class func heightWithAttributedString(attributedString: NSAttributedString, contentWidth: CGFloat) -> CGFloat {
            return attributedString.boundingRectWithSize(
                CGSizeMake(contentWidth, CGFloat.max),
                options: [.UsesLineFragmentOrigin],
                context: nil
            ).height + 30
        }
    }
    
    class LocationCell: UITableViewCell {
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: .Value1, reuseIdentifier: reuseIdentifier)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
