//
//  NCRemoteViewController.h
//  Newman Knights
//
//  Created by Nick Frey on 3/14/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCRemoteViewController : UIViewController

- (void)success;
- (void)failWithError:(NSError *)error;
- (void)retry;

@end
