//
//  NCEventDetailsCell.m
//  Newman Knights
//
//  Created by Nick Frey on 5/7/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCEventDetailsCell.h"
#import "NSDate+MNAdditions.h"

@interface NCEventDetailsCell ()

@property (nonatomic, strong) NSDictionary *titleAttributes;
@property (nonatomic, strong) NSDictionary *dateAttributes;
@property (nonatomic, strong) NSDictionary *detailAttributes;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic) UIEdgeInsets contentInsets;
@property (nonatomic) CGFloat lineSpacing;

@end

@implementation NCEventDetailsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.cellView.backgroundColor = [UIColor whiteColor];
        
        _titleAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:20]};
        _dateAttributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline], NSForegroundColorAttributeName: [UIColor colorWithWhite:0.5 alpha:1]};
        _detailAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14]};
        _contentInsets = UIEdgeInsetsMake(15, 15, 15, 15);
        _lineSpacing = 15;
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterLongStyle;
        
        _timeFormatter = [[NSDateFormatter alloc] init];
        _timeFormatter.dateFormat = @"h:mm a";
    }
    return self;
}

- (NSString *)headlineForEvent:(NCCalendarEvent *)event {
    NSMutableString *title = [event.title mutableCopy];
    
    if([event.gradeLevel length] > 0)
        [title insertString:[NSString stringWithFormat:@"%@ ", event.gradeLevel] atIndex:0];
    
    if(event.participantGender == NCCalendarEventParticipantGenderMale)
        [title insertString:@"Boys " atIndex:0];
    else if(event.participantGender == NCCalendarEventParticipantGenderFemale)
        [title insertString:@"Girls " atIndex:0];
    
    return [title copy];
}

- (NSString *)dateDescriptionForEvent:(NCCalendarEvent *)event {
    NSMutableString *date = [NSMutableString string];
    NSString *startDate = [_dateFormatter stringFromDate:event.startDate];
    NSString *startTime = [_timeFormatter stringFromDate:event.startDate];
    NSString *endTime = event.endDate ? [_timeFormatter stringFromDate:event.endDate] : nil;
    NSString *status = event.status;
    
    if(startDate)
        [date appendString:startDate];
    
    BOOL startTimeAvailable = [startTime length] > 0 && ![startTime isEqualToString:@"12:00 AM"];
    BOOL endTimeAvailable = [endTime length] > 0 && ![endTime isEqualToString:@"12:00 AM"];
    
    if(startTimeAvailable) {
        [date appendFormat:@"\n%@", startTime];
        if(endTimeAvailable) {
            [date appendFormat:@" to %@", endTime];
        }
    } else {
        if(endTimeAvailable) {
            [date appendFormat:@"Ends at %@", endTime];
        }
    }
    
    if([status length] > 0) {
        [date appendFormat:@"\n%@", status];
    }
    
    return [date copy];
}

- (CGFloat)heightForCalendarEvent:(NCCalendarEvent *)event {
    CGFloat width = self.frame.size.width - _contentInsets.left - _contentInsets.right;
    CGFloat y = _contentInsets.top;
    
    /* Title */
    NSString *title = [self headlineForEvent:event];
    if([title length] > 0) {
        CGRect titleRect = [title boundingRectWithSize:CGSizeMake(width, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:_titleAttributes context:nil];
        y += titleRect.size.height;
    }
    
    /* Date */
    NSString *date = [self dateDescriptionForEvent:event];
    if([date length] > 0) {
        CGRect dateRect = [date boundingRectWithSize:CGSizeMake(width, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:_dateAttributes context:nil];
        y += _lineSpacing + dateRect.size.height;
    }
    
    /* Comment */
    NSString *comment = event.details;
    if([comment length] > 0) {
        CGRect commentRect = [comment boundingRectWithSize:CGSizeMake(width, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:_detailAttributes context:nil];
        y += _lineSpacing + commentRect.size.height;
    }
    
    y += _contentInsets.bottom;
    
    return y;
}

- (void)drawCellView:(CGRect)rect {
    CGFloat width = self.frame.size.width - _contentInsets.left - _contentInsets.right;
    CGFloat y = _contentInsets.top;
    
    /* Title */
    NSString *title = [self headlineForEvent:_event];
    if([title length] > 0) {
        CGRect titleRect = [title boundingRectWithSize:CGSizeMake(width, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:_titleAttributes context:nil];
        [title drawInRect:CGRectMake(_contentInsets.left, y, titleRect.size.width, titleRect.size.height) withAttributes:_titleAttributes];
        y += titleRect.size.height + _lineSpacing;
    }
    
    /* Date */
    NSString *date = [self dateDescriptionForEvent:_event];
    if([date length] > 0) {
        CGRect dateRect = [date boundingRectWithSize:CGSizeMake(width, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:_dateAttributes context:nil];
        [date drawInRect:CGRectMake(_contentInsets.left, y, dateRect.size.width, dateRect.size.height) withAttributes:_dateAttributes];
        y += dateRect.size.height + _lineSpacing;
    }
    
    /* Comment */
    NSString *comment = _event.details;
    if([comment length] > 0) {
        CGRect commentRect = [comment boundingRectWithSize:CGSizeMake(width, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:_detailAttributes context:nil];
        [comment drawInRect:CGRectMake(_contentInsets.left, y, commentRect.size.width, commentRect.size.height) withAttributes:_detailAttributes];
    }
}

@end
