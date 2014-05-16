//
//  NCEventDetailsViewController.h
//  Newman Knights
//
//  Created by Nick Frey on 5/6/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCCalendarEvent.h"

@interface NCEventDetailsViewController : UITableViewController

@property (nonatomic, strong, readonly) NCCalendarEvent *event;

- (instancetype)initWithCalendarEvent:(NCCalendarEvent *)event;

@end
