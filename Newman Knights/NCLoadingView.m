//
//  NCLoadingView.m
//  Newman Knights
//
//  Created by Nick Frey on 3/14/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCLoadingView.h"

@implementation NCLoadingView

- (id)init {
    self = [super init];
    if (self) {
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [indicatorView startAnimating];
        [self addSubview:indicatorView];
        
        UILabel *indicatorText = [[UILabel alloc] init];
        indicatorText.text = NSLocalizedString(@"Loading...", @"Loading...");
        indicatorText.font = [UIFont systemFontOfSize:14];
        indicatorText.textColor = [UIColor darkGrayColor];
        indicatorText.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:indicatorText];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(indicatorView, indicatorText);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[indicatorView(20)]-(8)-[indicatorText]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[indicatorView]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[indicatorText]|" options:0 metrics:0 views:views]];
    }
    return self;
}

@end
