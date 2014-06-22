//
//  NCAppDelegate.m
//  Newman Knights
//
//  Created by Nick Frey on 10/10/13.
//  Copyright (c) 2013 Newman Catholic. All rights reserved.
//

#import "NCAppDelegate.h"
#import "NCHomeViewController.h"
#import "NCEventsViewController.h"
#import "NCGradesViewController.h"
#import "NCSocialViewController.h"
#import "NCSchedulesViewController.h"
#import "NCDocumentViewController.h"
#import "NCContactViewController.h"
#import "UITabBarController+Rotations.h"
#import "NCAppConfig.h"
#import "NCDataSource.h"

@interface NCAppDelegate ()

@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) NSArray *navigationControllers;
@property (nonatomic, strong) NCHomeViewController *homeViewController;

@end

@implementation NCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Global navigation bar settings
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigationBar"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setTintColor:[UIColor colorWithRed:223.0f/255.0f green:71.0f/255.0f blue:71.0f/255.0f alpha:1]];
    
    // Prepare view controllers
    NCHomeViewController *home = _homeViewController = [[NCHomeViewController alloc] init];
    NCEventsViewController *events = [[NCEventsViewController alloc] init];
    NCGradesViewController *grades = [[NCGradesViewController alloc] init];
    NCSocialViewController *social = [[NCSocialViewController alloc] init];
    NCSchedulesViewController *schedules = [[NCSchedulesViewController alloc] init];
    NCContactViewController *contact = [[NCContactViewController alloc] init];
    
    // Add them to tab bar
    NSArray *viewControllers = @[home, events, grades, social, schedules, contact];
    NSMutableArray *navControllers = [NSMutableArray array];
    
    for(UIViewController *viewController in viewControllers)
        [navControllers addObject:[[UINavigationController alloc] initWithRootViewController:viewController]];
    
    _tabBarController = [[UITabBarController alloc] init];
    _tabBarController.viewControllers = _navigationControllers = navControllers;
    _tabBarController.customizableViewControllers = nil;
    
    // Setup window
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.backgroundColor = [UIColor whiteColor];
    _window.rootViewController = _tabBarController;
    [_window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [_homeViewController reloadData];
    
    [[NCDataSource sharedDataSource] fetchAdditionalLinks:^(NSArray *links, NSDictionary *handbook) {
        NSMutableArray *viewControllers = [_navigationControllers mutableCopy];
        
        if(handbook) {
            UIViewController *viewController;
            
            if([handbook[@"document"] boolValue]) {
                viewController = [[NCDocumentViewController alloc] initWithDocumentID:handbook[@"url"]];
            } else {
                viewController = [[NCWebViewController alloc] initWithURL:[NSURL URLWithString:handbook[@"url"]]];
            }
            
            viewController.title = NSLocalizedString(@"Handbook", @"Handbook");
            viewController.tabBarItem.image = [UIImage imageNamed:@"tabHandbook"];
            
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
            [viewControllers insertObject:navController atIndex:viewControllers.count-1];
        }
        
        if(links) {
            for(NSDictionary *link in links) {
                UIViewController *viewController;
                
                if([link[@"document"] boolValue]) {
                    viewController = [[NCDocumentViewController alloc] initWithDocumentID:link[@"url"]];
                } else {
                    viewController = [[NCWebViewController alloc] initWithURL:[NSURL URLWithString:link[@"url"]]];
                }
                
                viewController.title = link[@"title"];
                viewController.tabBarItem.image = [UIImage imageNamed:@"tabLink"];
                
                [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:viewController]];
            }
        }
        
        _tabBarController.viewControllers = viewControllers;
        _tabBarController.customizableViewControllers = nil;
    }];
}

@end
