//
//  NCCoverViewPreviewItem.h
//  Newman Knights
//
//  Created by Nick Frey on 5/12/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

@interface NCCoverViewPreviewItem : NSObject <QLPreviewItem>

@property (nonatomic, strong) NSURL *url;

@end
