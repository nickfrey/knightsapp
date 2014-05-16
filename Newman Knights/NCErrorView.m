//
//  NCErrorView.m
//  Newman Knights
//
//  Created by Nick Frey on 3/14/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCErrorView.h"

@interface NCErrorView ()

@property (nonatomic, strong) UILabel *errorLabel;

@end

@implementation NCErrorView

- (id)init {
    self = [super init];
    if (self) {
        UIImageView *alertImageView = [[UIImageView alloc] init];
        alertImageView.image = [UIImage imageNamed:@"errorView"];
        alertImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:alertImageView];
        
        UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeSystem];
        retryButton.translatesAutoresizingMaskIntoConstraints = NO;
        retryButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [retryButton setTitle:NSLocalizedString(@"Retry", @"Retry") forState:UIControlStateNormal];
        [retryButton setTitleColor:[UIColor colorWithRed:0 green:122.0f/255.0f blue:1 alpha:1] forState:UIControlStateNormal];
        [retryButton setBackgroundImage:[UIImage imageNamed:@"roundedButton"] forState:UIControlStateNormal];
        [retryButton addTarget:self action:@selector(retry) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:retryButton];
        
        _errorLabel = [[UILabel alloc] init];
        _errorLabel.numberOfLines = 4;
        _errorLabel.font = [UIFont systemFontOfSize:15];
        _errorLabel.textColor = [UIColor darkGrayColor];
        _errorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_errorLabel];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(alertImageView, _errorLabel, retryButton);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[alertImageView(47)]" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_errorLabel]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[retryButton]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[alertImageView(42)][_errorLabel]-(10)-[retryButton(50)]|" options:0 metrics:0 views:views]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:alertImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    }
    return self;
}

- (void)setErrorMessage:(NSString *)errorMessage {
    _errorMessage = errorMessage;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setLineSpacing:4];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:errorMessage];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [errorMessage length])];
    _errorLabel.attributedText = attributedString;
}

- (void)retry {
    if([_delegate respondsToSelector:@selector(errorViewDidRequestRetry:)])
        [_delegate errorViewDidRequestRetry:self];
}

@end
