//
//  NCDailyEventsViewController.h
//  Newman Knights
//
//  Created by Nick Frey on 5/6/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCRemoteViewController.h"

@interface NCDailyEventsViewController : NCRemoteViewController

@property (nonatomic, strong, readonly) NSDate *date;

- (instancetype)initWithDate:(NSDate *)date;

@end
