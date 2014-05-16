//
//  NCEventStore.h
//  Newman Knights
//
//  Created by Nick Frey on 5/4/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCCalendarEvent.h"

@class NCEventStore;

@protocol NCEventStoreDelegate <NSObject>
@optional
- (void)eventStore:(NCEventStore *)eventStore didFetchEventsForMonthOfDate:(NSDate *)date;
@end

@interface NCEventStore : NSObject

@property (nonatomic, weak) id <NCEventStoreDelegate> delegate;
@property (nonatomic, strong, readonly) NSCalendar *calendar;

+ (instancetype)sharedInstance;

- (void)fetchEventsForDate:(NSDate *)date completion:(void (^)(NSArray *events, NSError *error))completionHandler;
- (void)fetchEventsWithQuery:(NSString *)query completion:(void (^)(NSArray *events, NSError *error))completionHandler;
- (void)cancelAllQueries;

- (void)updateEventsForMonthIfNeeded:(NSDate *)date;
- (BOOL)eventsOccurOnDate:(NSDate *)date;

@end
