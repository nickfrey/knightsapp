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

@interface NCAppDelegate ()

@property (nonatomic, strong) UITabBarController *tabBarController;

@end

@implementation NCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Global navigation bar settings
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigationBar"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[UIImage new]];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackTranslucent];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setTintColor:[UIColor colorWithRed:223.0f/255.0f green:71.0f/255.0f blue:71.0f/255.0f alpha:1]];
    
    // Prepare view controllers
    NCHomeViewController *home = [[NCHomeViewController alloc] init];
    NCEventsViewController *events = [[NCEventsViewController alloc] init];
    NCGradesViewController *grades = [[NCGradesViewController alloc] init];
    NCSocialViewController *social = [[NCSocialViewController alloc] init];
    NCSchedulesViewController *schedules = [[NCSchedulesViewController alloc] init];
    NCContactViewController *contact = [[NCContactViewController alloc] init];
    
    NCDocumentViewController *handbook = [[NCDocumentViewController alloc] initWithDocumentID:HANDBOOK_DOCUMENT_ID];
    handbook.title = NSLocalizedString(@"Handbook", @"Handbook");
    handbook.tabBarItem.image = [UIImage imageNamed:@"tabHandbook"];
    
    // Add them to tab bar
    NSArray *viewControllers = @[home, events, grades, social, schedules, handbook, contact];
    NSMutableArray *navControllers = [NSMutableArray array];
    
    for(UIViewController *viewController in viewControllers)
        [navControllers addObject:[[UINavigationController alloc] initWithRootViewController:viewController]];
    
    _tabBarController = [[UITabBarController alloc] init];
    _tabBarController.viewControllers = navControllers;
    
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.backgroundColor = [UIColor whiteColor];
    _window.rootViewController = _tabBarController;
    [_window makeKeyAndVisible];
    
    return YES;
}

@end
