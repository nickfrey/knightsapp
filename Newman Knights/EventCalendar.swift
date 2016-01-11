//
//  EventCalendar.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/21/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import Foundation

class EventCalendar {
    let calendar: NSCalendar
    
    private var datesBeingFetched: Set<NSDate>
    private var datesAlreadyFetched: Dictionary<NSDate, NSDate>
    private var datesContainingEvents: Set<NSDate>
    
    init() {
        self.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        self.datesBeingFetched = Set()
        self.datesAlreadyFetched = Dictionary()
        self.datesContainingEvents = Set()
    }
    
    // MARK: Class Methods
    class func fetchEvents(date: NSDate, completionHandler: (events: Array<Event>?, error: NSError?) -> Void) -> (() -> Void)? {
        let monthYearFormatter = NSDateFormatter()
        monthYearFormatter.dateFormat = "MM-yyyy"
        
        let dayFormatter = NSDateFormatter()
        dayFormatter.dateFormat = "dd"
        
        return self.fetchEvents([
            "ff_month_year": monthYearFormatter.stringFromDate(date),
            "ffDay": dayFormatter.stringFromDate(date)
            ], completionHandler: completionHandler)
    }
    
    class func fetchEvents(query: String, completionHandler: (events: Array<Event>?, error: NSError?) -> Void) -> (() -> Void)? {
        return self.fetchEvents([
            "G5statusflag": "view",
            "vw_schoolyear": "1",
            "search_text": query
            ], completionHandler: completionHandler)
    }
    
    private class func fetchEvents(parameters: Dictionary<String, String>, completionHandler: (events: Array<Event>?, error: NSError?) -> Void) -> (() -> Void)? {
        var queryItems = [
            NSURLQueryItem(name: "G5genie", value: "97"),
            NSURLQueryItem(name: "school_id", value: "5"),
            NSURLQueryItem(name: "XMLCalendar", value: "6")
        ]
        
        for (key, value) in parameters {
            queryItems.append(NSURLQueryItem(name: key, value: value))
        }
        
        let URLComponents = NSURLComponents(string: "http://www.northiowaconference.org/g5-bin/client.cgi")!
        URLComponents.queryItems = queryItems
        
        guard let URL = URLComponents.URL else {
            completionHandler(events: nil, error: NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil))
            return nil
        }
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(URL) { (data, response, error) -> Void in
            guard let data = data where error == nil
                else { return completionHandler(events: nil, error: error) }
            
            let xml = SWXMLHash.config({ config in
                config.shouldProcessNamespaces = true
            }).parse(data)
            
            var events = Array<Event>()
            for eventIndexer in xml["schema"]["element"] {
                guard let eventElement = eventIndexer.element where eventElement.attributes["name"] == "event"
                    else { continue }
                
                var event = Event()
                var eventType: String?
                var eventDate: String?
                var startTime: String?
                var endTime: String?
                
                for detailIndexer in eventIndexer["complexType"]["sequence"]["element"] {
                    guard let detailElement = detailIndexer.element
                        else { continue }
                    
                    let name = detailElement.attributes["name"]
                    let text = detailElement.text
                    
                    if name == "game_date" {
                        eventDate = text
                    } else if name == "start_time" {
                        startTime = text
                    } else if name == "end_time" {
                        endTime = text
                    } else if name == "type" {
                        eventType = text
                    } else if name == "identifier" {
                        event.identifier = text
                    } else if name == "sport" {
                        event.title = text
                    } else if name == "level" {
                        event.gradeLevel = text
                    } else if name == "gender" {
                        event.gender = text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    } else if name == "status" {
                        event.status = text?.stringByReplacingOccurrencesOfString("(", withString: "").stringByReplacingOccurrencesOfString(")", withString: "")
                    } else if name == "homeaway" {
                        event.away = (text == "Away")
                    } else if name == "location" {
                        for locationIndexer in detailIndexer["complexType"]["sequence"]["element"] {
                            guard let locationElement = locationIndexer.element where locationElement.attributes["name"] == "name"
                                else { continue }
                            
                            event.location = locationElement.text?.stringByReplacingOccurrencesOfString("@ ", withString: "")
                        }
                    } else if name == "opponent" {
                        if let text = text where detailElement.attributes["type"] == "xsd:string" {
                            event.opponents = text.componentsSeparatedByString(",")
                        }
                    } else if name == "comment" {
                        for commentIndexer in detailIndexer["complexType"]["sequence"]["element"] {
                            guard let commentElement = commentIndexer.element
                                else { continue }
                            guard let commentText = commentElement.text where commentText.characters.count > 0
                                else { continue }
                            
                            if let details = event.details {
                                event.details = details + "\n\n" + commentText
                            } else {
                                event.details = commentText
                            }
                        }
                    }
                }
                
                if let eventType = eventType {
                    if let title = event.title {
                        event.title = title + " " + eventType
                    } else {
                        event.title = eventType
                    }
                }
                
                // Start & end dates
                let dateFormatter = NSDateFormatter()
                let dateFormat = (parameters["G5statusflag"] == "view" ? "MM-dd-yy" : "yyyy-MM-dd")
                
                if var startDate = eventDate {
                    dateFormatter.dateFormat = dateFormat
                    
                    if let startTime = startTime where startTime.rangeOfString(":") != nil {
                        startDate += " " + startTime
                        dateFormatter.dateFormat = dateFormat + " hh:mma"
                    }
                    
                    event.startDate = dateFormatter.dateFromString(startDate)
                }
                
                if var endDate = eventDate {
                    dateFormatter.dateFormat = dateFormat
                    
                    if let endTime = endTime where endTime.rangeOfString(":") != nil {
                        endDate += " " + endTime
                        dateFormatter.dateFormat = dateFormat + " hh:mma"
                    }
                    
                    event.endDate = dateFormatter.dateFromString(endDate)
                }
                
                // Append the event
                events.append(event)
            }
            
            completionHandler(events: events, error: nil)
        }
        
        dataTask.resume()
        
        return {
            dataTask.cancel()
        }
    }
    
    // MARK: Instance Methods
    func fetchEventOccurrences(month: NSDate, completionHandler: (fetched: Bool, error: NSError?) -> Void) {
        guard let beginningOfMonth = self.calendar.dateBySettingUnit(.Day, value: 1, ofDate: month, options: [])
            else { return completionHandler(fetched: false, error: nil) }
        
        let fromDate = self.calendar.startOfDayForDate(beginningOfMonth)
        if let lastFetchDate = self.datesAlreadyFetched[fromDate] {
            if NSDate().timeIntervalSinceDate(lastFetchDate) < 60 * 10 {
                // If this month was fetched within last 10 minutes, use cache
                return completionHandler(fetched: false, error: nil)
            }
        }
        
        if self.datesBeingFetched.contains(fromDate) {
            return completionHandler(fetched: false, error: nil)
        } else {
            self.datesBeingFetched.insert(fromDate)
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let URL = NSURL(string: String(format: "http://srv2.advancedview.rschooltoday.com/public/conference/calendar/type/xml/G5genie/97/G5button/13/school_id/5/preview/no/vw_activity/0/vw_conference_events/1/vw_non_conference_events/1/vw_homeonly/1/vw_awayonly/1/vw_schoolonly/1/vw_gender/1/vw_type/0/vw_level/0/vw_opponent/0/opt_show_location/1/opt_show_comments/1/opt_show_bus_times/1/vw_location/0/vw_period/month-yr/vw_month2/%@/vw_monthCnt/01/vw_school_year/0/sortType/time/expandView/1/listact/0/dontshowlocation/1/", dateFormatter.stringFromDate(fromDate)))!
        
        NSURLSession.sharedSession().dataTaskWithURL(URL) { (data, response, error) -> Void in
            self.datesBeingFetched.remove(fromDate)
            
            guard let data = data where error == nil
                else { return completionHandler(fetched: true, error: error) }
            
            dateFormatter.dateFormat = "EEE, dd MMMM yyyy HH:mm:ss Z"
            dateFormatter.locale = NSLocale(localeIdentifier: "en")
            
            // Fetch succeeded
            let xml = SWXMLHash.parse(data)
            for eventIndexer in xml["rss"]["channel"]["item"] {
                guard let eventElement = eventIndexer.element else { continue }
                for childElement in eventElement.children {
                    if let text = childElement.text where childElement.name == "pubDate" {
                        if let pubDate = dateFormatter.dateFromString(text) {
                            self.datesContainingEvents.insert(self.calendar.startOfDayForDate(pubDate))
                        }
                        break
                    }
                }
            }
            
            self.datesAlreadyFetched[fromDate] = NSDate()
            completionHandler(fetched: true, error: nil)
        }.resume()
    }
    
    func eventsOccurOnDate(date: NSDate) -> Bool {
        return self.datesContainingEvents.contains(self.calendar.startOfDayForDate(date))
    }
}
