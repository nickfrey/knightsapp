//
//  NCWebViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 3/13/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCWebViewController.h"

@interface NCWebViewController ()

@property (nonatomic, strong) NSURL *initialURL;
@property (nonatomic, strong) UIPopoverController *activityPopoverController;

@end

@implementation NCWebViewController

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if(self) {
        _initialURL = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sharePage)];
    self.navigationItem.rightBarButtonItem = shareButton;
    
    _webView = [[UIWebView alloc] init];
    _webView.delegate = self;
    _webView.hidden = YES;
    _webView.scalesPageToFit = YES;
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_webView];
    [self.view sendSubviewToBack:_webView];

    NSDictionary *views = NSDictionaryOfVariableBindings(_webView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|" options:0 metrics:0 views:views]];

    [self loadPage];
}

- (void)retry {
    [super retry];
    [self loadPage];
}

#pragma mark - Internal

- (void)loadPage {
    if(_initialURL)
        [_webView loadRequest:[NSURLRequest requestWithURL:_initialURL]];
}

- (void)sharePage {
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[[self shareableURL]] applicationActivities:nil];
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        _activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
        [_activityPopoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        [self presentViewController:activityController animated:YES completion:nil];
    }
}

- (NSURL *)shareableURL {
    return _initialURL;
}

#pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    webView.hidden = YES;
    [self failWithError:error];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self success];
    webView.hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
