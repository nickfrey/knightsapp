//
//  AppConfiguration.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/31/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import Foundation

struct AppConfiguration {
    static let KnightsAPIURLString = "http://knights.nickfrey.me/api/"
    static let PowerSchoolURLString = "https://ps-archd.gwaea.org/public/home.html"
    
    struct School {
        static let Title = "Newman Catholic Schools"
        static let Subtitle = "Mason City, Iowa"
        static let PhoneNumber = "(641) 423-6939"
        static let Address = "2445 19th St. SW\nMason City, IA 50401"
        
        struct Coordinate {
            static let Latitude = 43.132737
            static let Longitude = -93.238699
        }
    }
    
    struct GoogleDrive {
        static let APIKey = ""
    }
    
    struct Twitter {
        static let ConsumerKey = ""
        static let ConsumerSecret = ""
    }
}
