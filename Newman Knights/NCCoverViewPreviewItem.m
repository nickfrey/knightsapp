//
//  NCCoverViewPreviewItem.m
//  Newman Knights
//
//  Created by Nick Frey on 5/12/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCCoverViewPreviewItem.h"

@implementation NCCoverViewPreviewItem

- (NSURL *)previewItemURL {
    return _url;
}

- (NSString *)previewItemTitle {
    return NSLocalizedString(@"Recently Tweeted", @"Recently Tweeted");
}

@end
