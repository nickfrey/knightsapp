//
//  UITabBarController+Rotations.m
//  Newman Knights
//
//  Created by Nick Frey on 5/4/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "UITabBarController+Rotations.h"

@implementation UITabBarController (Rotations)

- (BOOL)shouldAutorotate {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
}

- (NSUInteger)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}

@end
