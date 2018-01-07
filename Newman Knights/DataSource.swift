//
//  DataSource.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import Foundation

class DataSource {
    class func fetchBookmarks(_ completionHandler: @escaping (Array<Bookmark>?, Error?) -> Void) {
        URLSession.shared.dataTask(with: URL(string: AppConfiguration.KnightsAPIURLString + "?action=info")!, completionHandler: { (data, response, error) -> Void in
            guard let data = data, error == nil
                else { return completionHandler(nil, error) }
            
            do {
                let response = try JSONSerialization.jsonObject(with: data, options: []) as! Dictionary<String, Any>
                var bookmarks = Array<Bookmark>()
                
                if let links = response["links"] as? Array<Dictionary<String, AnyObject>> {
                    for link in links {
                        guard let title = link["title"] as? String else { continue }
                        guard let url = link["url"] as? String else { continue }
                        
                        if let isDocument = link["document"] as? Bool, isDocument {
                            bookmarks.append(Bookmark(title: title, icon: .default, URL: nil, documentID: url))
                        } else if let URL = URL(string: url) {
                            bookmarks.append(Bookmark(title: title, icon: .default, URL: URL, documentID: nil))
                        }
                    }
                }
                
                if let handbook = response["handbook"] as? Dictionary<String, AnyObject> {
                    if let url = handbook["url"] as? String {
                        if let isDocument = handbook["document"] as? Bool, isDocument {
                            bookmarks.append(Bookmark(title: "Handbook", icon: .book, URL: nil, documentID: url))
                        } else if let URL = URL(string: url) {
                            bookmarks.append(Bookmark(title: "Handbook", icon: .book, URL: URL, documentID: nil))
                        }
                    }
                }
                
                completionHandler(bookmarks, nil)
            } catch _ {
                completionHandler(nil, nil)
            }
        }).resume()
    }
    
    class func fetchSchedules(_ completionHandler: @escaping (Array<Schedule>?, Error?) -> Void) {
        URLSession.shared.dataTask(with: URL(string: AppConfiguration.KnightsAPIURLString + "?action=schedules")!, completionHandler: { (data, response, error) -> Void in
            guard let data = data, error == nil
                else { return completionHandler(nil, error) }
            
            do {
                let response = try JSONSerialization.jsonObject(with: data, options: []) as! Dictionary<String, Any>
                var schedules = Array<Schedule>()
                
                if let responses = response["schedules"] as? Array<Dictionary<String, AnyObject>> {
                    for schedule in responses {
                        guard let title = schedule["title"] as? String else { continue }
                        guard let url = schedule["url"] as? String else { continue }
                        
                        if let isDocument = schedule["document"] as? Bool, isDocument {
                            schedules.append(Schedule(title: title, URL: nil, documentID: url))
                        } else if let URL = URL(string: url) {
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
        }).resume()
    }
    
    class func fetchContacts(_ directory: Contact.Directory, completionHandler: @escaping (Array<Contact>?, Error?) -> Void) {
        var directoryString: String
        
        switch directory {
        case .administration:
            directoryString = "administration"
        case .faculty:
            directoryString = "faculty"
        case .office:
            directoryString = "office"
        }
        
        let fetchURL = URL(string: AppConfiguration.KnightsAPIURLString + "?action=contacts&directory=" + directoryString)
        URLSession.shared.dataTask(with: fetchURL!, completionHandler: { (data, response, error) -> Void in
            guard let data = data, error == nil
                else { return completionHandler(nil, error) }
            
            do {
                let response = try JSONSerialization.jsonObject(with: data, options: [])
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
        }).resume()
    }
    
    class func fetchSocialPosts(_ count: Int?, completionHandler: @escaping (Array<SocialPost>?, Error?) -> Void) {
        let twitter = Swifter(
            consumerKey: AppConfiguration.Twitter.ConsumerKey,
            consumerSecret: AppConfiguration.Twitter.ConsumerSecret,
            appOnly: true
        )
        
        twitter.authorizeAppOnly(success: { (accessToken, response) in
            twitter.getTimeline(
                for: "356522712",
                count: count,
                sinceID: nil,
                maxID: nil,
                trimUser: nil,
                contributorDetails: nil,
                includeEntities: true,
                success: { (jsonResponse) -> Void in
                    guard let statuses = jsonResponse.array
                        else { return completionHandler(nil, nil) }
                    
                    var tweets = Array<SocialPost>()
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "en_US")
                    dateFormatter.dateFormat = "EEE MMM d HH:mm:ss Z y"
                    
                    for status in statuses {
                        var status = status
                        if status["retweeted_status"].object != nil {
                            status = status["retweeted_status"]
                        }
                        
                        guard let identifier = status["id_str"].string else { continue }
                        guard let content = status["text"].string else { continue }
                        guard let createdAt = status["created_at"].string else { continue }
                        guard let creationDate = dateFormatter.date(from: createdAt) else { continue }
                        let avatarURLString = status["user"]["profile_image_url_https"].string?.replacingOccurrences(of: "_normal", with: "_bigger")
                        
                        var images = Array<URL>()
                        if let mediaEntities = status["entities"]["media"].array {
                            for mediaEntity in mediaEntities {
                                guard let mediaType = mediaEntity["type"].string, mediaType == "photo"
                                    else { continue }
                                guard let mediaURLString = mediaEntity["media_url_https"].string
                                    else { continue }
                                
                                if let URL = URL(string: mediaURLString) {
                                    images.append(URL)
                                }
                            }
                        }
                        
                        tweets.append(SocialPost(
                            identifier: identifier,
                            author: SocialPost.Author(
                                username: status["user"]["screen_name"].string,
                                displayName: status["user"]["name"].string,
                                avatarURL: (avatarURLString != nil ? URL(string: avatarURLString!) : nil)
                            ),
                            content: content,
                            creationDate: creationDate,
                            images: images,
                            permalink: nil,
                            source: .twitter,
                            retweetCount: status["retweet_count"].integer,
                            favoriteCount: status["favorite_count"].integer
                        ))
                    }
                    completionHandler(tweets, nil)
            }, failure: { (error) -> Void in
                completionHandler(nil, error)
            })
        }, failure: { (error) in
            completionHandler(nil, error)
        })
    }
}
