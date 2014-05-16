//
//  NCScheduleCell.m
//  Newman Knights
//
//  Created by Nick Frey on 5/4/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCScheduleCell.h"

@interface NCScheduleCell ()

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation NCScheduleCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderColor = [UIColor colorWithRed:200.0f/255.0f green:199.0f/255.0f blue:204.0f/255.0f alpha:1].CGColor;
        self.layer.borderWidth = 1;
        self.layer.cornerRadius = 8;
        self.layer.masksToBounds = YES;
        
        self.selectedBackgroundView = [UIView new];
        self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:217.0f/255.0f alpha:1];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:18];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_titleLabel];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_titleLabel);
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_titleLabel]|" options:0 metrics:0 views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_titleLabel]|" options:0 metrics:0 views:views]];
    }
    return self;
}

- (void)setScheduleTitle:(NSString *)scheduleTitle {
    _scheduleTitle = scheduleTitle;
    _titleLabel.text = scheduleTitle;
}

@end
