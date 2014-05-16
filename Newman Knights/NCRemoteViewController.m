//
//  NCRemoteViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 3/14/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCRemoteViewController.h"
#import "NCLoadingView.h"
#import "NCErrorView.h"

@interface NCRemoteViewController () <NCErrorViewDelegate>

@property (nonatomic, strong) NCLoadingView *loadingView;
@property (nonatomic, strong) NCErrorView *errorView;

@end

@implementation NCRemoteViewController

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor colorWithRed:239.0f/255.0f green:239.0f/255.0f blue:244.0f/255.0f alpha:1];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    
    _loadingView = [[NCLoadingView alloc] init];
    _loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_loadingView];
    
    _errorView = [[NCErrorView alloc] init];
    _errorView.hidden = YES;
    _errorView.delegate = self;
    _errorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_errorView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_loadingView, _errorView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_loadingView(100)]" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_loadingView(20)]" options:0 metrics:0 views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_loadingView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_loadingView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_errorView(250)]" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_errorView(190)]" options:0 metrics:0 views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_errorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_errorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
}

- (void)failWithError:(NSError *)error {
    [self performSelector:@selector(displayError:) withObject:error afterDelay:1];
}

- (void)displayError:(NSError *)error {
    _loadingView.hidden = YES;
    _errorView.errorMessage = error.localizedDescription;
    _errorView.hidden = NO;
}

- (void)success {
    _loadingView.hidden = YES;
    _errorView.hidden = YES;
}

- (void)retry {
    _errorView.hidden = YES;
    _loadingView.hidden = NO;
}

#pragma mark - NCErrorViewDelegate

- (void)errorViewDidRequestRetry:(NCErrorView *)errorView {
    [self retry];
}

@end
