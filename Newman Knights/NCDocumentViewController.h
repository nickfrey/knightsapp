//
//  NCDocumentViewController.h
//  Newman Knights
//
//  Created by Nick Frey on 3/14/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCWebViewController.h"

@interface NCDocumentViewController : NCWebViewController

- (instancetype)initWithDocumentID:(NSString *)documentID;

@end
