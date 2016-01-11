//
//  AppDelegate.swift
//  Newman Knights
//
//  Created by Nick Frey on 12/20/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var tabBarController: UITabBarController?
    private var navigationControllers: [UINavigationController] = []
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Global navigation bar settings
        UINavigationBar.appearance().barStyle = .Black
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().setBackgroundImage(UIImage(named: "navigationBar"), forBarMetrics: .Default)
        
        // Prepare view controllers
        let viewControllers = [
            NewsViewController(),
            CalendarViewController(),
            GradesViewController(),
            SocialViewController(),
            SchedulesViewController(),
            ContactViewController(),
        ]
        
        self.navigationControllers = viewControllers.map({ (viewController) -> UINavigationController in
            return UINavigationController(rootViewController: viewController)
        })
        
        // Setup window
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = self.navigationControllers
        tabBarController.customizableViewControllers = nil
        self.tabBarController = tabBarController
        
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.backgroundColor = UIColor.whiteColor()
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        self.window = window
        
        if #available(iOS 9.0, *) {
            if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
                self.application(application, performActionForShortcutItem: shortcutItem, completionHandler: {_ in })
            }
        }
        
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        DataSource.fetchBookmarks { (bookmarks, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                guard let bookmarks = bookmarks where error == nil
                    else { return }
                
                var navigationControllers = self.navigationControllers
                for bookmark in bookmarks {
                    let viewController: UIViewController
                    
                    if let documentID = bookmark.documentID {
                        viewController = DocumentViewController(identifier: documentID)
                    } else if let URL = bookmark.URL {
                        viewController = WebViewController(URL: URL)
                    } else {
                        continue
                    }
                    
                    viewController.title = bookmark.title
                    viewController.tabBarItem.image = self.imageForBookmarkIcon(bookmark.icon)
                    navigationControllers.append(UINavigationController(rootViewController: viewController))
                }
                
                self.tabBarController?.viewControllers = navigationControllers
                self.tabBarController?.customizableViewControllers = nil
            })
        }
    }
    
    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        if shortcutItem.type == "org.newmancatholic.knightsapp.shortcut.events" {
            self.tabBarController?.selectedIndex = 1
        } else if shortcutItem.type == "org.newmancatholic.knightsapp.shortcut.grades" {
            self.tabBarController?.selectedIndex = 2
        } else if shortcutItem.type == "org.newmancatholic.knightsapp.shortcut.social" {
            self.tabBarController?.selectedIndex = 3
        }
    }
    
    private func imageForBookmarkIcon(icon: Bookmark.Icon) -> UIImage? {
        switch icon {
        case .Default:
            return UIImage(named: "tabLink")
        case .Book:
            return UIImage(named: "tabHandbook")
        }
    }
}
