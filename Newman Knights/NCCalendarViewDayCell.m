//
//  NCCalendarViewDayCell.m
//  Newman Knights
//
//  Created by Nick Frey on 5/3/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCCalendarViewDayCell.h"
#import "NCEventStore.h"

@interface NCCalendarViewDayCell ()

@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic) CGFloat indicatorSize;

@end

@implementation NCCalendarViewDayCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _selectedColor = self.selectedBackgroundView.backgroundColor;
        self.selectedBackgroundView = nil;
        
        _indicatorSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? 12 : 8;
    }
    return self;
}

- (void)setDate:(NSDate *)date month:(NSDate *)month calendar:(NSCalendar *)calendar {
    [super setDate:date month:month calendar:calendar];
    
    if(self.enabled) {
        [[NCEventStore sharedInstance] updateEventsForMonthIfNeeded:month];
        self.eventful = [[NCEventStore sharedInstance] eventsOccurOnDate:date];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        self.titleLabel.font = [UIFont systemFontOfSize:18];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.backgroundColor = highlighted ? _selectedColor : [UIColor whiteColor];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.backgroundColor = selected ? _selectedColor : [UIColor whiteColor];
}

- (void)setEventful:(BOOL)eventful {
    _eventful = eventful;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if(_eventful && self.enabled) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.frame.size.width, 0)];
        [path addLineToPoint:CGPointMake(self.frame.size.width, _indicatorSize)];
        [path addLineToPoint:CGPointMake(self.frame.size.width-_indicatorSize, 0)];
        [path closePath];
        [[UIColor redColor] set];
        [path fill];
    }
}
@end
