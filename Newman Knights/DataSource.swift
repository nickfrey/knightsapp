//
//  DataSource.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import Foundation

class DataSource {
    class func fetchBookmarks(completionHandler: (Array<Bookmark>?, NSError?) -> Void) {
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: AppConfiguration.KnightsAPIURLString + "?action=info")!) { (data, response, error) -> Void in
            guard let data = data where error == nil
                else { return completionHandler(nil, error) }
            
            do {
                let response = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                var bookmarks = Array<Bookmark>()
                
                if let links = response["links"] as? Array<Dictionary<String, AnyObject>> {
                    for link in links {
                        guard let title = link["title"] as? String else { continue }
                        guard let url = link["url"] as? String else { continue }
                        
                        if let isDocument = link["document"] as? Bool where isDocument {
                            bookmarks.append(Bookmark(title: title, icon: .Default, URL: nil, documentID: url))
                        } else if let URL = NSURL(string: url) {
                            bookmarks.append(Bookmark(title: title, icon: .Default, URL: URL, documentID: nil))
                        }
                    }
                }
                
                if let handbook = response["handbook"] as? Dictionary<String, AnyObject> {
                    if let url = handbook["url"] as? String {
                        if let isDocument = handbook["document"] as? Bool where isDocument {
                            bookmarks.append(Bookmark(title: "Handbook", icon: .Book, URL: nil, documentID: url))
                        } else if let URL = NSURL(string: url) {
                            bookmarks.append(Bookmark(title: "Handbook", icon: .Book, URL: URL, documentID: nil))
                        }
                    }
                }
                
                completionHandler(bookmarks, nil)
            } catch _ {
                completionHandler(nil, nil)
            }
        }.resume()
    }
    
    class func fetchSchedules(completionHandler: (Array<Schedule>?, NSError?) -> Void) {
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: AppConfiguration.KnightsAPIURLString + "?action=schedules")!) { (data, response, error) -> Void in
            guard let data = data where error == nil
                else { return completionHandler(nil, error) }
            
            do {
                let response = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                var schedules = Array<Schedule>()
                
                if let responses = response["schedules"] as? Array<Dictionary<String, AnyObject>> {
                    for schedule in responses {
                        guard let title = schedule["title"] as? String else { continue }
                        guard let url = schedule["url"] as? String else { continue }
                        
                        if let isDocument = schedule["document"] as? Bool where isDocument {
                            schedules.append(Schedule(title: title, URL: nil, documentID: url))
                        } else if let URL = NSURL(string: url) {
                            schedules.append(Schedule(title: title, URL: URL, documentID: nil))
                        }
                    }
                }
                
                completionHandler(schedules, nil)
            } catch _ {
                let fallbackError = NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorBadServerResponse,
                    userInfo: [NSLocalizedDescriptionKey: "A bad response was received from the server."]
                )
                completionHandler(nil, fallbackError)
            }
        }.resume()
    }
    
    class func fetchContacts(directory: Contact.Directory, completionHandler: (Array<Contact>?, NSError?) -> Void) {
        var directoryString: String
        
        switch directory {
        case .Administration:
            directoryString = "administration"
        case .Faculty:
            directoryString = "faculty"
        case .Office:
            directoryString = "office"
        }
        
        let URL = NSURL(string: AppConfiguration.KnightsAPIURLString + "?action=contacts&directory=" + directoryString)
        NSURLSession.sharedSession().dataTaskWithURL(URL!) { (data, response, error) -> Void in
            guard let data = data where error == nil
                else { return completionHandler(nil, error) }
            
            do {
                let response = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                var contacts = Array<Contact>()
                
                if let response = response as? Array<Dictionary<String, AnyObject>> {
                    for contact in response {
                        guard let name = contact["name"] as? String else { continue }
                        guard let title = contact["title"] as? String else { continue }
                        guard let email = contact["email"] as? String else { continue }
                        contacts.append(Contact(name: name, title: title, email: email))
                    }
                }
                
                completionHandler(contacts, nil)
            } catch _ {
                let fallbackError = NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorBadServerResponse,
                    userInfo: [NSLocalizedDescriptionKey: "A bad response was received from the server."]
                )
                completionHandler(nil, fallbackError)
            }
        }.resume()
    }
    
    class func fetchSocialPosts(count: Int?, completionHandler: (Array<SocialPost>?, NSError?) -> Void) {
        let twitter = Swifter(
            consumerKey: AppConfiguration.Twitter.ConsumerKey,
            consumerSecret: AppConfiguration.Twitter.ConsumerSecret,
            appOnly: true
        )
        
        twitter.authorizeAppOnlyWithSuccess({ (accessToken, response) -> Void in
            twitter.getStatusesUserTimelineWithUserID("356522712",
                count: count,
                sinceID: nil,
                maxID: nil,
                trimUser: nil,
                contributorDetails: nil,
                includeEntities: true,
                success: { (statuses) -> Void in
                    guard let statuses = statuses
                        else { return completionHandler(nil, nil) }
                    
                    var tweets = Array<SocialPost>()
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.locale = NSLocale(localeIdentifier: "en_US")
                    dateFormatter.dateFormat = "EEE MMM d HH:mm:ss Z y"
                    
                    for status in statuses {
                        var status = status
                        if status["retweeted_status"].object != nil {
                            status = status["retweeted_status"]
                        }
                        
                        guard let identifier = status["id_str"].string else { continue }
                        guard let content = status["text"].string else { continue }
                        guard let createdAt = status["created_at"].string else { continue }
                        guard let creationDate = dateFormatter.dateFromString(createdAt) else { continue }
                        let avatarURLString = status["user"]["profile_image_url_https"].string?.stringByReplacingOccurrencesOfString("_normal", withString: "_bigger")
                        
                        var images = Array<NSURL>()
                        if let mediaEntities = status["entities"]["media"].array {
                            for mediaEntity in mediaEntities {
                                guard let mediaType = mediaEntity["type"].string where mediaType == "photo"
                                    else { continue }
                                guard let mediaURLString = mediaEntity["media_url_https"].string
                                    else { continue }
                                
                                if let URL = NSURL(string: mediaURLString) {
                                    images.append(URL)
                                }
                            }
                        }
                        
                        tweets.append(SocialPost(
                            identifier: identifier,
                            author: SocialPost.Author(
                                username: status["user"]["screen_name"].string,
                                displayName: status["user"]["name"].string,
                                avatarURL: (avatarURLString != nil ? NSURL(string: avatarURLString!) : nil)
                            ),
                            content: content,
                            creationDate: creationDate,
                            images: images,
                            permalink: nil,
                            source: .Twitter,
                            retweetCount: status["retweet_count"].integer,
                            favoriteCount: status["favorite_count"].integer
                        ))
                    }
                    completionHandler(tweets, nil)
                }, failure: { (error) -> Void in
                    completionHandler(nil, error)
                })
            }) { (error) -> Void in
                completionHandler(nil, error)
        }
    }
}
