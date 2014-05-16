//
//  NCEventOpponentsCell.h
//  Newman Knights
//
//  Created by Nick Frey on 5/7/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCCalendarEvent.h"
#import "NCEfficientTableViewCell.h"

@interface NCEventOpponentsCell : NCEfficientTableViewCell

@property (nonatomic, weak) NCCalendarEvent *event;

- (CGFloat)heightForCalendarEvent:(NCCalendarEvent *)event;

@end
