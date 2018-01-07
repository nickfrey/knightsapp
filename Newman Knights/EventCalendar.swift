//
//  EventCalendar.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/21/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import Foundation

class EventCalendar {
    let calendar: Calendar
    
    fileprivate var datesBeingFetched: Set<Date>
    fileprivate var datesAlreadyFetched: Dictionary<Date, Date>
    fileprivate var datesContainingEvents: Set<Date>
    
    init() {
        self.calendar = Calendar(identifier: .gregorian)
        self.datesBeingFetched = Set()
        self.datesAlreadyFetched = Dictionary()
        self.datesContainingEvents = Set()
    }
    
    // MARK: Class Methods
    class func fetchEvents(_ date: Date, completionHandler: @escaping (_ events: Array<Event>?, _ error: Error?) -> Void) -> (() -> Void)? {
        let monthYearFormatter = DateFormatter()
        monthYearFormatter.dateFormat = "MM-yyyy"
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "dd"
        
        return self.fetchEvents([
            "ff_month_year": monthYearFormatter.string(from: date),
            "ffDay": dayFormatter.string(from: date)
            ], completionHandler: completionHandler)
    }
    
    class func fetchEvents(_ query: String, completionHandler: @escaping (_ events: Array<Event>?, _ error: Error?) -> Void) -> (() -> Void)? {
        return self.fetchEvents([
            "G5statusflag": "view",
            "vw_schoolyear": "1",
            "search_text": query
            ], completionHandler: completionHandler)
    }
    
    fileprivate class func fetchEvents(_ parameters: Dictionary<String, String>, completionHandler: @escaping (_ events: Array<Event>?, _ error: Error?) -> Void) -> (() -> Void)? {
        var queryItems = [
            URLQueryItem(name: "G5genie", value: "97"),
            URLQueryItem(name: "school_id", value: "5"),
            URLQueryItem(name: "XMLCalendar", value: "6")
        ]
        
        for (key, value) in parameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        var fetchURLComponents = URLComponents(string: "http://www.northiowaconference.org/g5-bin/client.cgi")!
        fetchURLComponents.queryItems = queryItems
        
        guard let fetchURL = fetchURLComponents.url else {
            completionHandler(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil))
            return nil
        }
        
        let dataTask = URLSession.shared.dataTask(with: fetchURL, completionHandler: { (data, response, error) -> Void in
            guard let data = data, error == nil
                else { return completionHandler(nil, error) }
            
            let xml = SWXMLHash.config({ config in
                config.shouldProcessNamespaces = true
            }).parse(data)
            
            var events = Array<Event>()
            for eventIndexer in xml["schema"]["element"].children {
                guard let eventElement = eventIndexer.element, eventElement.attribute(by: "name")?.text == "event"
                    else { continue }
                
                var event = Event()
                var eventType: String?
                var eventDate: String?
                var startTime: String?
                var endTime: String?
                
                for detailIndexer in eventIndexer["complexType"]["sequence"]["element"].children {
                    guard let detailElement = detailIndexer.element
                        else { continue }
                    
                    let name = detailElement.attribute(by: "name")?.text
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
                        event.gender = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    } else if name == "status" {
                        event.status = text.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                    } else if name == "homeaway" {
                        event.away = (text == "Away")
                    } else if name == "location" {
                        for locationIndexer in detailIndexer["complexType"]["sequence"]["element"].children {
                            guard let locationElement = locationIndexer.element, locationElement.attribute(by: "name")?.text == "name"
                                else { continue }
                            
                            event.location = locationElement.text.replacingOccurrences(of: "@ ", with: "")
                        }
                    } else if name == "opponent" {
                        if detailElement.attribute(by: "type")?.text == "xsd:string" {
                            event.opponents = text.components(separatedBy: ",")
                        }
                    } else if name == "comment" {
                        for commentIndexer in detailIndexer["complexType"]["sequence"]["element"].children {
                            guard let commentElement = commentIndexer.element
                                else { continue }
                            
                            let commentText = commentElement.text
                            guard commentText.count > 0
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
                let dateFormatter = DateFormatter()
                let dateFormat = (parameters["G5statusflag"] == "view" ? "MM-dd-yy" : "yyyy-MM-dd")
                
                if var startDate = eventDate {
                    dateFormatter.dateFormat = dateFormat
                    
                    if let startTime = startTime, startTime.range(of: ":") != nil {
                        startDate += " " + startTime
                        dateFormatter.dateFormat = dateFormat + " hh:mma"
                    }
                    
                    event.startDate = dateFormatter.date(from: startDate)
                }
                
                if var endDate = eventDate {
                    dateFormatter.dateFormat = dateFormat
                    
                    if let endTime = endTime, endTime.range(of: ":") != nil {
                        endDate += " " + endTime
                        dateFormatter.dateFormat = dateFormat + " hh:mma"
                    }
                    
                    event.endDate = dateFormatter.date(from: endDate)
                }
                
                // Append the event
                events.append(event)
            }
            
            completionHandler(events, nil)
        })
        
        dataTask.resume()
        
        return {
            dataTask.cancel()
        }
    }
    
    // MARK: Instance Methods
    func fetchEventOccurrences(_ month: Date, completionHandler: @escaping (_ fetched: Bool, _ error: Error?) -> Void) {
        guard let beginningOfMonth = self.calendar.date(bySetting: .day, value: 1, of: month)
            else { return completionHandler(false, nil) }
        
        let fromDate = self.calendar.startOfDay(for: beginningOfMonth)
        if let lastFetchDate = self.datesAlreadyFetched[fromDate] {
            if Date().timeIntervalSince(lastFetchDate) < 60 * 10 {
                // If this month was fetched within last 10 minutes, use cache
                return completionHandler(false, nil)
            }
        }
        
        if self.datesBeingFetched.contains(fromDate) {
            return completionHandler(false, nil)
        } else {
            self.datesBeingFetched.insert(fromDate)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let fetchURL = URL(string: String(format: "http://srv2.advancedview.rschooltoday.com/public/conference/calendar/type/xml/G5genie/97/G5button/13/school_id/5/preview/no/vw_activity/0/vw_conference_events/1/vw_non_conference_events/1/vw_homeonly/1/vw_awayonly/1/vw_schoolonly/1/vw_gender/1/vw_type/0/vw_level/0/vw_opponent/0/opt_show_location/1/opt_show_comments/1/opt_show_bus_times/1/vw_location/0/vw_period/month-yr/vw_month2/%@/vw_monthCnt/01/vw_school_year/0/sortType/time/expandView/1/listact/0/dontshowlocation/1/", dateFormatter.string(from: fromDate)))!
        
        URLSession.shared.dataTask(with: fetchURL, completionHandler: { (data, response, error) -> Void in
            self.datesBeingFetched.remove(fromDate)
            
            guard let data = data, error == nil
                else { return completionHandler(true, error) }
            
            dateFormatter.dateFormat = "EEE, dd MMMM yyyy HH:mm:ss Z"
            dateFormatter.locale = Locale(identifier: "en")
            
            // Fetch succeeded
            let xml = SWXMLHash.parse(data)
            for eventIndexer in xml["rss"]["channel"]["item"].children {
                guard let eventElement = eventIndexer.element else { continue }
                for childElement in eventElement.xmlChildren {
                    if childElement.name == "pubDate" {
                        if let pubDate = dateFormatter.date(from: childElement.text) {
                            self.datesContainingEvents.insert(self.calendar.startOfDay(for: pubDate))
                        }
                        break
                    }
                }
            }
            
            self.datesAlreadyFetched[fromDate] = Date()
            completionHandler(true, nil)
        }).resume()
    }
    
    func eventsOccurOnDate(_ date: Date) -> Bool {
        return self.datesContainingEvents.contains(self.calendar.startOfDay(for: date))
    }
}
