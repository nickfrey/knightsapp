//
//  NCDataSource.h
//  Newman Knights
//
//  Created by Nick Frey on 10/12/13.
//  Copyright (c) 2013 Newman Catholic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCSocialPost.h"

typedef NS_ENUM(NSUInteger, NCContactDirectory) {
    NCContactDirectoryAdministration,
    NCContactDirectoryOffice,
    NCContactDirectoryFaculty
};

@interface NCDataSource : NSObject

+ (instancetype)sharedDataSource;
- (void)fetchBulletin:(void (^)(NSArray *events, NSError *error))completionHandler;
- (void)fetchSchedules:(void (^)(NSArray *schedules, NSError *error))completionHandler;
- (void)fetchSocialPosts:(void (^)(NSArray *posts, NSError *error))completionHandler;
- (void)fetchContactDirectory:(NCContactDirectory)directory completion:(void (^)(NSArray *contacts, NSError *error))completionHandler;

@end
