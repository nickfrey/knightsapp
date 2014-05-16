//
//  NCCalendarEvent.h
//  Newman Knights
//
//  Created by Nick Frey on 4/30/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NCCalendarEventParticipantGender) {
    NCCalendarEventParticipantNoGender,
    NCCalendarEventParticipantGenderMale,
    NCCalendarEventParticipantGenderFemale
};

@interface NCCalendarEvent : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *details;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *gradeLevel;

@property (nonatomic, getter = isAway) BOOL away;
@property (nonatomic, strong) NSArray *opponents;
@property (nonatomic) NCCalendarEventParticipantGender participantGender;

@end
