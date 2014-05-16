//
//  NCEventStore.m
//  Newman Knights
//
//  Created by Nick Frey on 5/4/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCEventStore.h"
#import "AFNetworking.h"
#import "XMLDictionary.h"
#import "NSDate+MNAdditions.h"

@interface NCEventStore ()

@property (nonatomic, strong) NSMutableSet *datesBeingFetched;
@property (nonatomic, strong) NSMutableDictionary *lastDateFetches;
@property (nonatomic, strong) NSMutableSet *eventfulDates;
@property (nonatomic, strong) NSMutableArray *searchQueue;

@end

@implementation NCEventStore

static NCEventStore *sharedInstance;

+ (instancetype)sharedInstance {
    static NCEventStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if(self) {
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        _datesBeingFetched = [[NSMutableSet alloc] init];
        _lastDateFetches = [[NSMutableDictionary alloc] init];
        _eventfulDates = [[NSMutableSet alloc] init];
        _searchQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Monthly events

- (void)updateEventsForMonthIfNeeded:(NSDate *)date {
    if(!date) return;
    
    NSDate *fromDate = [date mn_firstDateOfMonth:_calendar];
    if([_datesBeingFetched containsObject:fromDate]) return;
    [_datesBeingFetched addObject:fromDate];
    
    NSDate *lastFetchDate = _lastDateFetches[fromDate];
    if(lastFetchDate) {
        NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:lastFetchDate];
        if(elapsedTime < 60*10) return; // Auto-fetched within last 10 minutes
    }
    _lastDateFetches[fromDate] = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"YYYY-MM-dd";
    
    /* Fetch */
    NSURL *baseURL = [NSURL URLWithString:@"http://srv2.advancedview.rschooltoday.com"];
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSString *path = [NSString stringWithFormat:@"/public/conference/calendar/type/xml/G5genie/97/G5button/13/school_id/5/preview/no/vw_activity/0/vw_conference_events/1/vw_non_conference_events/1/vw_homeonly/1/vw_awayonly/1/vw_schoolonly/1/vw_gender/1/vw_type/0/vw_level/0/vw_opponent/0/opt_show_location/1/opt_show_comments/1/opt_show_bus_times/1/vw_location/0/vw_period/month-yr/vw_month2/%@/vw_monthCnt/01/vw_school_year/0/sortType/time/expandView/1/listact/0/dontshowlocation/1/", [dateFormatter stringFromDate:date]];
    
    [manager GET:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *document = [NSDictionary dictionaryWithXMLData:responseObject];
        if(![document isKindOfClass:[NSDictionary class]]) return;
        
        id items = document[@"channel"][@"item"];
        NSArray *itemsArray;
        
        // As single item is parsed as a dictionary
        if([items isKindOfClass:[NSDictionary class]])
            itemsArray = @[items];
        else if([items isKindOfClass:[NSArray class]])
            itemsArray = items;
        
        NSDateFormatter *pubDateFormatter = [[NSDateFormatter alloc] init];
        pubDateFormatter.dateFormat = @"EEE, dd MMMM yyyy HH:mm:ss Z";
        pubDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
        
        for(NSDictionary *event in itemsArray) {
            NSDate *pubDate = [[pubDateFormatter dateFromString:event[@"pubDate"]] mn_beginningOfDay:_calendar];
            if(![_eventfulDates containsObject:pubDate])
                [_eventfulDates addObject:pubDate];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if([self.delegate respondsToSelector:@selector(eventStore:didFetchEventsForMonthOfDate:)])
                [self.delegate eventStore:self didFetchEventsForMonthOfDate:fromDate];
        });
    } failure:nil];
}

- (BOOL)eventsOccurOnDate:(NSDate *)date {
    return [_eventfulDates containsObject:[date mn_beginningOfDay:_calendar]];
}

#pragma mark - Event details

- (AFHTTPRequestOperation *)fetchEventsWithParameters:(NSDictionary *)parameters completion:(void (^)(NSArray *, NSError *))completionHandler {
    NSURL *baseURL = [NSURL URLWithString:@"http://www.northiowaconference.org/"];
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSMutableDictionary *params = [parameters mutableCopy];
    params[@"G5genie"] = @"97";
    params[@"school_id"] = @"5";
    params[@"XMLCalendar"] = @"6";
    
    return [manager GET:@"/g5-bin/client.cgi" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *document = [NSDictionary dictionaryWithXMLData:responseObject];
        NSMutableArray *events = [NSMutableArray array];
        id elements = document[@"xsd:element"];
        NSArray *eventItems;
        
        // As single item is parsed as a dictionary
        if([elements isKindOfClass:[NSDictionary class]])
            eventItems = @[elements];
        else if([elements isKindOfClass:[NSArray class]])
            eventItems = elements;
        
        for(NSDictionary *eventItem in eventItems) {
            NSDictionary *eventDetails = eventItem[@"xsd:complexType"][@"xsd:sequence"][@"xsd:element"];
            NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
            
            // Organize event details into 'attributes'
            for(NSDictionary *detailDictionary in eventDetails) {
                NSString *attributeName = detailDictionary[@"_name"];

                if([attributeName isEqualToString:@"location"] ||
                   [attributeName isEqualToString:@"opponent"] ||
                   [attributeName isEqualToString:@"comment"])
                {
                    NSArray *attributeDetails = detailDictionary[@"xsd:complexType"][@"xsd:sequence"][@"xsd:element"];

                    for(NSDictionary *dict in attributeDetails) {
                        if([attributeName isEqualToString:@"location"]) {
                            if([dict[@"_name"] isEqualToString:@"name"]) {
                                NSString *location;
                                if((location = dict[@"__text"]))
                                    attributes[attributeName] = [location stringByReplacingOccurrencesOfString:@"@ " withString:@""];
                            }
                        } else if([attributeName isEqualToString:@"opponent"]) {
                            if([dict[@"_name"] isEqualToString:@"name"]) {
                                NSString *opponent;
                                if((opponent = dict[@"__text"]))
                                    attributes[attributeName] = [opponent componentsSeparatedByString:@","];
                            }
                        } else {
                            if([dict[@"_name"] isEqualToString:@"conference"]) {
                                NSString *conference;
                                if((conference = dict[@"__text"]))
                                    attributes[attributeName] = conference;
                            }
                        }
                    }
                } else {
                    NSString *attributeValue = detailDictionary[@"__text"];
                    if(attributeValue)
                        attributes[attributeName] = attributeValue;
                }
            }
                        
            // Construct event
            NCCalendarEvent *event = [[NCCalendarEvent alloc] init];
            event.identifier = attributes[@"id"];
            event.title = attributes[@"sport"];
            event.details = attributes[@"comment"];
            event.status = [[attributes[@"status"] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""];
            event.location = attributes[@"location"];
            event.gradeLevel = attributes[@"level"];
            event.opponents = attributes[@"opponent"];
            event.away = [attributes[@"homeaway"] isEqualToString:@"Away"];
            
            if(attributes[@"type"])
                event.title = [event.title stringByAppendingFormat:@" %@", attributes[@"type"]];
            
            // Assign gender
            NSString *gender = attributes[@"gender"];
            if([gender isEqualToString:@"Boys"]) {
                event.participantGender = NCCalendarEventParticipantGenderMale;
            } else if([gender isEqualToString:@"Girls"]) {
                event.participantGender = NCCalendarEventParticipantGenderFemale;
            }
            
            // Determine start and end dates
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            NSString *gameDate = attributes[@"game_date"];
            NSMutableString *startDate = [gameDate mutableCopy];
            NSMutableString *endDate = [gameDate mutableCopy];
            
            NSString *YMDFormat = @"yyyy-MM-dd";
            if([parameters[@"G5statusflag"] isEqualToString:@"view"])
                YMDFormat = @"MM-dd-yy";
            
            if(attributes[@"start_time"] && [attributes[@"start_time"] rangeOfString:@":"].location != NSNotFound) {
                [startDate appendFormat:@" %@", attributes[@"start_time"]];
                dateFormatter.dateFormat = [YMDFormat stringByAppendingString:@" hh:mma"];
            } else {
                dateFormatter.dateFormat = YMDFormat;
            }
            
            event.startDate = [dateFormatter dateFromString:startDate];
            
            if(attributes[@"end_time"] && [attributes[@"end_time"] rangeOfString:@":"].location != NSNotFound) {
                [endDate appendFormat:@" %@", attributes[@"end_time"]];
                dateFormatter.dateFormat = [YMDFormat stringByAppendingString:@" hh:mma"];
            } else {
                dateFormatter.dateFormat = YMDFormat;
            }
            event.endDate = [dateFormatter dateFromString:endDate];
            
            // Add to output array
            [events addObject:event];
        }
        
        completionHandler([events copy], nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completionHandler(nil, error);
    }];
}

- (void)fetchEventsForDate:(NSDate *)date completion:(void (^)(NSArray *, NSError *))completionHandler {
    if(!date) return completionHandler(nil, nil);
    
    NSDateFormatter *monthYearFormatter = [[NSDateFormatter alloc] init];
    monthYearFormatter.dateFormat = @"MM-yyyy";
    
    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
    dayFormatter.dateFormat = @"dd";
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"ff_month_year"] = [monthYearFormatter stringFromDate:date];
    parameters[@"ffDay"] = [dayFormatter stringFromDate:date];
    
    [self fetchEventsWithParameters:parameters completion:completionHandler];
}

- (void)fetchEventsWithQuery:(NSString *)query completion:(void (^)(NSArray *, NSError *))completionHandler {
    if(!query) return completionHandler(nil, nil);
    
    AFHTTPRequestOperation *operation = [self fetchEventsWithParameters:@{@"G5statusflag": @"view", @"vw_schoolyear": @"1", @"search_text": query} completion:completionHandler];
    [_searchQueue addObject:operation];
}

- (void)cancelAllQueries {
    for(AFHTTPRequestOperation *operation in _searchQueue) {
        [operation cancel];
    }
    [_searchQueue removeAllObjects];
}

@end
