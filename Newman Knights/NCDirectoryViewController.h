//
//  NCDirectoryViewController.h
//  Newman Knights
//
//  Created by Nick Frey on 5/12/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCRemoteViewController.h"
#import "NCDataSource.h"

@interface NCDirectoryViewController : NCRemoteViewController

@property (nonatomic, readonly) NCContactDirectory directory;

- (instancetype)initWithDirectory:(NCContactDirectory)directory;

@end
