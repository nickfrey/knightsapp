//
//  NCDailyEventCell.h
//  Newman Knights
//
//  Created by Nick Frey on 5/7/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCCalendarEvent.h"

@interface NCDailyEventCell : UITableViewCell

@property (nonatomic, weak) NCCalendarEvent *event;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
