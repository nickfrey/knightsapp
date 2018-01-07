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
    fileprivate var tabBarController: UITabBarController?
    fileprivate var navigationControllers: [UINavigationController] = []
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Global navigation bar settings
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().setBackgroundImage(UIImage(named: "navigationBar"), for: .default)
        
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
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        self.window = window
        
        if #available(iOS 9.0, *) {
            if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
                self.application(application, performActionFor: shortcutItem, completionHandler: {_ in })
            }
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        DataSource.fetchBookmarks { (bookmarks, error) -> Void in
            DispatchQueue.main.async(execute: {
                guard let bookmarks = bookmarks, error == nil
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
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == "org.newmancatholic.knightsapp.shortcut.events" {
            self.tabBarController?.selectedIndex = 1
        } else if shortcutItem.type == "org.newmancatholic.knightsapp.shortcut.grades" {
            self.tabBarController?.selectedIndex = 2
        } else if shortcutItem.type == "org.newmancatholic.knightsapp.shortcut.social" {
            self.tabBarController?.selectedIndex = 3
        }
    }
    
    fileprivate func imageForBookmarkIcon(_ icon: Bookmark.Icon) -> UIImage? {
        switch icon {
        case .default:
            return UIImage(named: "tabLink")
        case .book:
            return UIImage(named: "tabHandbook")
        }
    }
}
