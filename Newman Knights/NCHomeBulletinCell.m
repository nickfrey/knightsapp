//
//  NCHomeBulletinCell.m
//  Newman Knights
//
//  Created by Nick Frey on 5/11/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCHomeBulletinCell.h"

/*
@interface NCAutoresizingLabel : UILabel
@end

@implementation NCAutoresizingLabel

- (id)init {
    self = [super init];
    if(self) {
        self.lineBreakMode = NSLineBreakByWordWrapping;
        [self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if(self.numberOfLines == 0) {
        if(self.preferredMaxLayoutWidth != self.bounds.size.width) {
            self.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds);
            [super layoutSubviews];
        }
    }
}

@end
 */

@interface NCHomeBulletinCell ()

@property (nonatomic, strong) UILabel *bulletinLabel;

@end

@implementation NCHomeBulletinCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if(self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _bulletinLabel = [[UILabel alloc] init];
        _bulletinLabel.numberOfLines = 0;
        _bulletinLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_bulletinLabel];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_bulletinLabel);
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[_bulletinLabel]-15-|" options:0 metrics:0 views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_bulletinLabel]-10-|" options:0 metrics:0 views:views]];
    }
    return self;
}

- (void)setBulletinText:(NSString *)bulletinText {
    _bulletinText = bulletinText;
    _bulletinLabel.text = bulletinText;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _bulletinLabel.preferredMaxLayoutWidth = CGRectGetWidth(_bulletinLabel.frame);
}

@end
