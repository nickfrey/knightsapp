//
//  NCSocialPost.h
//  Newman Knights
//
//  Created by Nick Frey on 3/20/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCSocialPost : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSArray *attachments;
@property (nonatomic, strong) NSURL *permalink;

- (void)openInExternalApplication;

@end

@interface NCTwitterPost : NCSocialPost

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSURL *avatarURL;
@property (nonatomic) NSUInteger retweetCount;
@property (nonatomic) NSUInteger favoriteCount;

@end
