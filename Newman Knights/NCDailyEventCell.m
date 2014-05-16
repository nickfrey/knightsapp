//
//  NCDailyEventCell.m
//  Newman Knights
//
//  Created by Nick Frey on 5/7/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCDailyEventCell.h"

@interface NCDailyEventCell ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation NCDailyEventCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if(self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"h:mm a";
    }
    return self;
}

- (void)setEvent:(NCCalendarEvent *)event {
    _event = event;
    
    NSMutableString *eventTitle = [event.title mutableCopy];
    NSMutableArray *eventDetails = [NSMutableArray array];
    
    if([event.gradeLevel length] > 0)
        [eventTitle insertString:[NSString stringWithFormat:@"%@ ", event.gradeLevel] atIndex:0];
    
    if(event.participantGender == NCCalendarEventParticipantGenderMale)
        [eventTitle insertString:@"Boys " atIndex:0];
    else if(event.participantGender == NCCalendarEventParticipantGenderFemale)
        [eventTitle insertString:@"Girls " atIndex:0];
    
    NSString *startTime = [_dateFormatter stringFromDate:event.startDate];
    if(startTime && ![startTime isEqualToString:@"12:00 AM"]) [eventDetails addObject:startTime];
    
    if([event.location length] > 0 && ![event.location isEqualToString:@"Newman Catholic"])
        [eventDetails addObject:[NSString stringWithFormat:@"@ %@", event.location]];
    else if([event.details length] > 0)
        [eventDetails addObject:event.details];
    
    if([event.status length] > 0)
        [eventDetails addObject:[NSString stringWithFormat:@"(%@)", event.status]];
    
    self.textLabel.text = eventTitle;
    self.detailTextLabel.text = [eventDetails componentsJoinedByString:@" "];
}

@end
