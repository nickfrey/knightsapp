//
//  NCDataSource.m
//  Newman Knights
//
//  Created by Nick Frey on 10/12/13.
//  Copyright (c) 2013 Newman Catholic. All rights reserved.
//

#import "NCDataSource.h"
#import "NCAppConfig.h"
#import "XMLDictionary.h"
#import "AFNetworking.h"
#import "STTwitter.h"
#import "NSString+HTML.h"
#import "NSDate+MNAdditions.h"

@interface NCDataSource ()

@property (nonatomic, strong) STTwitterAPI *twitterAPI;

@end

@implementation NCDataSource

+ (instancetype)sharedDataSource {
    static NCDataSource *sharedDataSource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDataSource = [[self alloc] init];
    });
    return sharedDataSource;
}

- (id)init {
    self = [super init];
    if(self) {
        _twitterAPI = [STTwitterAPI twitterAPIAppOnlyWithConsumerKey:TWITTER_CONSUMER_KEY consumerSecret:TWITTER_CONSUMER_SECRET];
    }
    return self;
}

#pragma mark - Social

- (void)authenticateTwitterRequest:(void (^)(NSError *error))completion {
    if(_twitterAPI.oauthAccessToken) {
        // Already authenticated
        completion(nil);
        return;
    }
    
    [_twitterAPI verifyCredentialsWithSuccessBlock:^(NSString *bearerToken) {
        completion(nil);
    } errorBlock:^(NSError *error) {
        completion(error);
    }];
}

- (void)fetchSocialPosts:(void (^)(NSArray *, NSError *))completionHandler {
    [self authenticateTwitterRequest:^(NSError *error) {
        if(error) {
            completionHandler(nil, error);
        } else {
            [_twitterAPI getUserTimelineWithScreenName:@"NewmanKnights" count:25 successBlock:^(NSArray *statuses) {
                NSMutableArray *tweets = [NSMutableArray array];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
                [dateFormatter setDateFormat:@"EEE MMM d HH:mm:ss Z y"];
                
                for(NSDictionary *status in statuses) {
                    NSDictionary *statusInfo = status;
                    if(status[@"retweeted_status"])
                        statusInfo = status[@"retweeted_status"];
                    
                    NCTwitterPost *tweet = [[NCTwitterPost alloc] init];
                    tweet.text = statusInfo[@"text"];
                    tweet.identifier = statusInfo[@"id_str"];
                    tweet.creationDate = [dateFormatter dateFromString:statusInfo[@"created_at"]];
                    tweet.username = statusInfo[@"user"][@"screen_name"];
                    tweet.displayName = statusInfo[@"user"][@"name"];
                    tweet.retweetCount = [statusInfo[@"retweet_count"] unsignedIntegerValue];
                    tweet.favoriteCount = [statusInfo[@"favorite_count"] unsignedIntegerValue];

                    NSString *avatarURL = [statusInfo[@"user"][@"profile_image_url_https"] stringByReplacingOccurrencesOfString:@"_normal" withString:@"_bigger"];
                    tweet.avatarURL = [NSURL URLWithString:avatarURL];
                    
                    NSArray *media = statusInfo[@"entities"][@"media"];
                    if([media isKindOfClass:[NSArray class]] && [media count] > 0) {
                        NSMutableArray *attachments = [NSMutableArray array];
                        for(NSDictionary *mediaInfo in media) {
                            if([mediaInfo[@"type"] isEqualToString:@"photo"])
                                [attachments addObject:[NSURL URLWithString:mediaInfo[@"media_url_https"]]];
                        }
                        tweet.attachments = [attachments copy];
                    }
                    
                    [tweets addObject:tweet];
                }
                
                completionHandler(tweets, nil);
            } errorBlock:^(NSError *error) {
                completionHandler(nil, error);
            }];
        }
    }];
}

/*
NSArray *twitterAccounts = @[@"NewmanKnights", @"NewmanMusicDept", @"Newman_AD", @"NewmanCounselor", @"NewmanFB", @"NewmanBaseball", @"basketballNCHS", @"NewmanGBB", @"NewmanVB", @"NewmanKnightsXC"];
*/

#pragma mark - Newman Catholic

- (void)fetchBulletin:(void (^)(NSArray *, NSError *))completion {
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://newmancatholic.org"]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSDictionary *parameters = @{@"option": @"com_content", @"view": @"featured", @"format": @"feed", @"type": @"rss"};
    
    [manager GET:@"/"
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
        NSDictionary *rssFeed = [NSDictionary dictionaryWithXMLData:responseObject];
        NSMutableString *bulletinText = [[rssFeed valueForKeyPath:@"channel.item.description"] mutableCopy];
        NSMutableArray *weeklyBulletin = [NSMutableArray array];
        
        // Strip HTML
        [bulletinText replaceOccurrencesOfString:@"<br>" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, bulletinText.length)];
        [bulletinText replaceOccurrencesOfString:@"<br />" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, bulletinText.length)];
        [bulletinText replaceOccurrencesOfString:@"&nbsp;" withString:@" " options:0 range:NSMakeRange(0, bulletinText.length)];
        
        NSRange r;
        while ((r = [bulletinText rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
            [bulletinText replaceCharactersInRange:r withString:@""];
        
        // Detect dates
        NSString *pattern = @"(?:(Sun(?:day)?|Mon(?:day)?|Tue(?:sday)?|Wed(?:nesday)?|Thu(?:rsday)?|Fri(?:day)?|Sat(?:urday)?))?.*?((?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Sept|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)).*?(:)";
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeDate error:NULL];
        NSArray *matches = [regex matchesInString:bulletinText options:0 range:NSMakeRange(0, [bulletinText length])];
        
        NSUInteger matchIndex = 0;
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match range];
            NSString *eventText;
            
            if(matchIndex+1 < [matches count]) {
                NSRange nextMatchRange = [matches[matchIndex+1] range];
                eventText = [bulletinText substringWithRange:NSMakeRange(matchRange.location, nextMatchRange.location-matchRange.location)];
            } else {
                eventText = [bulletinText substringWithRange:NSMakeRange(matchRange.location, [bulletinText length]-matchRange.location)];
            }
            
            // strip date and split events by line
            NSTextCheckingResult *dateMatch = [detector firstMatchInString:eventText options:0 range:NSMakeRange(0, [eventText length])];
            eventText = [eventText stringByReplacingCharactersInRange:NSMakeRange(0, matchRange.length) withString:@""];
            eventText = [eventText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray *eventTextComponents = [eventText componentsSeparatedByString:@"\n"];
            NSMutableArray *eventsList = [NSMutableArray array];
            
            // remove empty new lines
            for(NSString *eventListText in eventTextComponents) {
                if([eventListText length] > 0) {
                    NSString *decodedString = [[NSString alloc] initWithData:[eventListText dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] encoding:NSUTF8StringEncoding];
                    
                    decodedString = [decodedString gtm_stringByUnescapingFromHTML];
                    decodedString = [decodedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if([decodedString length] > 0) {
                        [eventsList addObject:decodedString];
                    }
                }
            }
            
            NSDate *beginningOfDay = [[NSDate date] mn_beginningOfDay:[NSCalendar currentCalendar]];
            if(dateMatch.date && beginningOfDay && [dateMatch.date compare:beginningOfDay] != NSOrderedAscending) {
                [weeklyBulletin addObject:@{@"date": dateMatch.date, @"events":eventsList}];
            }
            matchIndex++;
        }
        
        completion(weeklyBulletin, nil);
             
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)fetchSchedules:(void (^)(NSArray *, NSError *))completion {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager GET:KNIGHTS_API_URL
      parameters:@{@"action": @"schedules"}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
        if([responseObject isKindOfClass:[NSDictionary class]])
            if([responseObject[@"schedules"] isKindOfClass:[NSArray class]])
                return completion(responseObject[@"schedules"], nil);

        NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:@{NSLocalizedDescriptionKey: @"This document could not be located."}];
        completion(nil, error);
             
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)fetchContactDirectory:(NCContactDirectory)directory completion:(void (^)(NSArray *, NSError *))completion {
    NSString *directoryName;
    
    switch(directory) {
        case NCContactDirectoryAdministration:
            directoryName = @"administration";
            break;
        case NCContactDirectoryOffice:
            directoryName = @"office";
            break;
        case NCContactDirectoryFaculty:
            directoryName = @"faculty";
            break;
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager GET:KNIGHTS_API_URL
      parameters:@{@"action": @"contacts", @"directory": directoryName}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
        if([responseObject isKindOfClass:[NSArray class]])
            return completion(responseObject, nil);
        
        NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:@{NSLocalizedDescriptionKey: @"An unknown server error occurred."}];
        completion(nil, error);
             
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
}

- (void)fetchAdditionalLinks:(void (^)(NSArray *, NSDictionary *))completionHandler {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager GET:KNIGHTS_API_URL
      parameters:@{@"action": @"info"}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
        if([responseObject isKindOfClass:[NSDictionary class]])
            if([responseObject[@"links"] isKindOfClass:[NSArray class]])
                completionHandler(responseObject[@"links"], responseObject[@"handbook"]);
             
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completionHandler(nil, nil);
    }];
}

@end
