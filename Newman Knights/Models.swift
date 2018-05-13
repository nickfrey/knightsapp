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
        case `default`
        case book
    }
    
    var title: String
    var icon: Icon
    var URL: URL?
    var documentID: String?
}

struct Schedule {
    var title: String
    var URL: URL?
    var documentID: String?
}

struct Contact {
    enum Directory {
        case administration
        case office
        case faculty
    }
    
    var name: String
    var title: String
    var email: String
}

struct SocialPost {
    struct Author {
        var username: String?
        var displayName: String?
        var avatarURL: URL?
    }
    
    enum Source {
        case twitter
        case facebook
    }
    
    var identifier: String
    var author: Author
    var content: String
    var creationDate: Date
    var images: Array<URL>
    var permalink: URL?
    var source: Source
    var retweetCount: Int?
    var favoriteCount: Int?
    
    func openInExternalApplication() {
        if self.source == .twitter {
            var URLString: String
            
            if UIApplication.shared.canOpenURL(URL(string: "tweetbot://")!) {
                URLString = "tweetbot://" + self.author.username! + "/status/" + self.identifier
            } else if UIApplication.shared.canOpenURL(URL(string: "twitter://")!) {
                URLString = "twitter://status?id=" + self.identifier
            } else {
                URLString = "https://twitter.com/" + self.author.username! + "/status/" + self.identifier
            }
            
            UIApplication.shared.openURL(URL(string: URLString)!)
        } else if let permalink = self.permalink {
            UIApplication.shared.openURL(permalink)
        }
    }
}

struct Event {
    var identifier: String?
    var title: String?
    var details: String?
    var startDate: Date?
    var endDate: Date?
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
        
        if let gradeLevel = self.gradeLevel, gradeLevel.count > 0 {
            eventTitle = gradeLevel + " " + eventTitle
        }
        
        if let gender = self.gender, gender.count > 0 {
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
