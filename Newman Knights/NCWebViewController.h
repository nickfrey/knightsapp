//
//  NCWebViewController.h
//  Newman Knights
//
//  Created by Nick Frey on 3/13/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCRemoteViewController.h"

@interface NCWebViewController : NCRemoteViewController <UIWebViewDelegate>

@property (nonatomic, strong, readonly) UIWebView *webView;

- (instancetype)initWithURL:(NSURL *)url;
- (void)loadPage;
- (NSURL *)shareableURL;

@end
