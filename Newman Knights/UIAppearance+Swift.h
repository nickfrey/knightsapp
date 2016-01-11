//
//  UIAppearance+Swift.h
//  Newman Knights
//
//  Created by Nick Frey on 12/22/15.
//  Copyright © 2015 Nick Frey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Swift)

+ (instancetype)swift_appearanceWhenContainedIn:(NSArray<Class<UIAppearanceContainer>> *)containerClasses;

@end
