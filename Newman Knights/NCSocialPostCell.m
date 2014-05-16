//
//  NCSocialPostCell.m
//  Newman Knights
//
//  Created by Nick Frey on 5/10/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCSocialPostCell.h"
#import "MHPrettyDate.h"
#import "UIImageView+AFNetworking.h"

@interface NCSocialPostCell ()

@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIImageView *avatarImageView;

@end

@implementation NCSocialPostCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.separatorInset = UIEdgeInsetsMake(0, 10, 0, 0);
        
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_avatarImageView];
        
        _displayNameLabel = [[UILabel alloc] init];
        _displayNameLabel.font = [UIFont boldSystemFontOfSize:15];
        _displayNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_displayNameLabel];
        
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.numberOfLines = 0;
        _contentLabel.font = [UIFont systemFontOfSize:14];
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_contentLabel];
        
        _dateLabel = [[UILabel alloc] init];
        _dateLabel.font = [UIFont systemFontOfSize:14];
        _dateLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
        _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_dateLabel];
        
        NSNumber *paddingL = @(70);
        NSNumber *paddingR = @(15);
        NSNumber *paddingT = @(10);
        NSNumber *paddingB = @(10);
        NSNumber *avatarSize = @(50);
        
        NSDictionary *metrics = NSDictionaryOfVariableBindings(paddingL, paddingR, paddingT, paddingB, avatarSize);
        NSDictionary *views = NSDictionaryOfVariableBindings(_avatarImageView, _displayNameLabel, _contentLabel, _dateLabel);

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-paddingT-[_avatarImageView(avatarSize)]" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-paddingT-[_avatarImageView(avatarSize)]" options:0 metrics:metrics views:views]];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-paddingL-[_displayNameLabel]-paddingR-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-paddingL-[_contentLabel]-paddingR-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-paddingL-[_dateLabel]-paddingR-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-paddingT-[_displayNameLabel]-2-[_contentLabel]-2-[_dateLabel]-paddingB-|" options:0 metrics:metrics views:views]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _displayNameLabel.preferredMaxLayoutWidth = CGRectGetWidth(_displayNameLabel.frame);
    _contentLabel.preferredMaxLayoutWidth = CGRectGetWidth(_contentLabel.frame);
    _dateLabel.preferredMaxLayoutWidth = CGRectGetWidth(_dateLabel.frame);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _avatarImageView.image = nil;
    _displayNameLabel.text = nil;
    _contentLabel.text = nil;
    _dateLabel.text = nil;
}

- (void)setPost:(NCSocialPost *)post {
    _post = post;
    
    if([post isKindOfClass:[NCTwitterPost class]]) {
        NCTwitterPost *twitterPost = (NCTwitterPost *)post;
        _displayNameLabel.text = twitterPost.displayName;
        [_avatarImageView setImageWithURL:twitterPost.avatarURL];
    }
    
    _contentLabel.text = post.text;
    _dateLabel.text = [MHPrettyDate prettyDateFromDate:post.creationDate withFormat:MHPrettyDateLongRelativeTime];
}

@end
