//
//  Models.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import Foundation

struct Bookmark {
    enum Icon {
        case Default
        case Book
    }
    
    var title: String
    var icon: Icon
    var URL: NSURL?
    var documentID: String?
}

struct Schedule {
    var title: String
    var URL: NSURL?
    var documentID: String?
}

struct Contact {
    enum Directory {
        case Administration
        case Office
        case Faculty
    }
    
    var name: String
    var title: String
    var email: String
}

struct SocialPost {
    struct Author {
        var username: String?
        var displayName: String?
        var avatarURL: NSURL?
    }
    
    enum Source {
        case Twitter
        case Facebook
    }
    
    var identifier: String
    var author: Author
    var content: String
    var creationDate: NSDate
    var images: Array<NSURL>
    var permalink: NSURL?
    var source: Source
    var retweetCount: Int?
    var favoriteCount: Int?
    
    func openInExternalApplication() {
        if self.source == .Twitter {
            var URLString: String
            
            if UIApplication.sharedApplication().canOpenURL(NSURL(string: "tweetbot://")!) {
                URLString = "tweetbot://" + self.author.username! + "/status/" + self.identifier
            } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "twitter://")!) {
                URLString = "twitter://status?id=" + self.identifier
            } else {
                URLString = "https://twitter.com/" + self.author.username! + "/status/" + self.identifier
            }
            
            UIApplication.sharedApplication().openURL(NSURL(string: URLString)!)
        } else if let permalink = self.permalink {
            UIApplication.sharedApplication().openURL(permalink)
        }
    }
}

struct Event {
    var identifier: String?
    var title: String?
    var details: String?
    var startDate: NSDate?
    var endDate: NSDate?
    var status: String?
    var location: String?
    var gradeLevel: String?
    var gender: String?
    var away: Bool = false
    var opponents: Array<String> = []
    
    func computedTitle() -> String? {
        var eventTitle = ""
        
        if let title = self.title {
            eventTitle = title
        }
        
        if let gradeLevel = self.gradeLevel where gradeLevel.characters.count > 0 {
            eventTitle = gradeLevel + " " + eventTitle
        }
        
        if let gender = self.gender where gender.characters.count > 0 {
            eventTitle = gender + " " + eventTitle
        }
        
        return eventTitle
    }
}

extension Event: Equatable {}
func ==(lhs: Event, rhs: Event) -> Bool {
    return (lhs.title == rhs.title &&
        lhs.details == rhs.details &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate &&
        lhs.status == rhs.status &&
        lhs.location == rhs.location &&
        lhs.gradeLevel == rhs.gradeLevel &&
        lhs.gender == rhs.gender &&
        lhs.away == rhs.away &&
        lhs.opponents == rhs.opponents)
}
