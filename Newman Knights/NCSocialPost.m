//
//  NCSocialPost.m
//  Newman Knights
//
//  Created by Nick Frey on 3/20/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCSocialPost.h"

@implementation NCSocialPost

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p, id: %@, text: %@, date: %@, attachments: %@>", NSStringFromClass([self class]), self, _identifier, _text, _creationDate, _attachments];
}

- (BOOL)isEqual:(id)object {
    if([object isKindOfClass:[self class]]) {
        return [self.identifier isEqualToString:[object identifier]];
    } else {
        return [super isEqual:object];
    }
}

- (void)openInExternalApplication {
    if(_permalink)
        [[UIApplication sharedApplication] openURL:_permalink];
}

@end

@implementation NCTwitterPost

- (void)openInExternalApplication {
    NSString *urlString;
    
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
        urlString = [NSString stringWithFormat:@"tweetbot://%@/status/%@", self.username, self.identifier];
    } else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        urlString = [NSString stringWithFormat:@"twitter://status?id=%@", self.identifier];
    } else {
        urlString = [NSString stringWithFormat:@"http://twitter.com/%@/status/%@", self.username, self.identifier];
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

@end