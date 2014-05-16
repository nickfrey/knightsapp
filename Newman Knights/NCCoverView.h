//
//  NCCoverView.h
//  Newman Knights
//
//  Created by Nick Frey on 3/22/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCCoverView : UIView

@property (nonatomic, strong) NSArray *coverPosts;
@property (nonatomic, strong, readonly) UIImage *currentImage;

@end
