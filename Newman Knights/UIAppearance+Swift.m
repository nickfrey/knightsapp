//
//  UIAppearance+Swift.m
//  Newman Knights
//
//  Created by Nick Frey on 12/22/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

#import "UIAppearance+Swift.h"

@implementation UIBarButtonItem (Swift)

+ (instancetype)swift_appearanceWhenContainedIn:(NSArray<Class<UIAppearanceContainer>> *)containerClasses {
    NSUInteger count = containerClasses.count;
    NSAssert(count <= 10, @"The count of containers greater than 10 is not supported.");
    
    return [self appearanceWhenContainedIn:
            count > 0 ? containerClasses[0] : nil,
            count > 1 ? containerClasses[1] : nil,
            count > 2 ? containerClasses[2] : nil,
            count > 3 ? containerClasses[3] : nil,
            count > 4 ? containerClasses[4] : nil,
            count > 5 ? containerClasses[5] : nil,
            count > 6 ? containerClasses[6] : nil,
            count > 7 ? containerClasses[7] : nil,
            count > 8 ? containerClasses[8] : nil,
            count > 9 ? containerClasses[9] : nil,
            nil];
}

@end
