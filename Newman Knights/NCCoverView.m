//
//  NCCoverView.m
//  Newman Knights
//
//  Created by Nick Frey on 3/22/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCCoverView.h"
#import "NCSocialPost.h"
#import "UIImageView+AFNetworking.h"

@interface NCCoverView ()

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) NSTimer *swapTimer;
@property (nonatomic) NSUInteger coverIndex;

@end

@implementation NCCoverView

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
        
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.clipsToBounds = YES;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_coverImageView];
        
        UIImageView *shadowView = [[UIImageView alloc] init];
        shadowView.image = [[UIImage imageNamed:@"coverShadow"] stretchableImageWithLeftCapWidth:8 topCapHeight:8];
        shadowView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:shadowView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_coverImageView, shadowView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_coverImageView]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_coverImageView]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[shadowView]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[shadowView]|" options:0 metrics:0 views:views]];
    }
    return self;
}

- (void)setCoverPosts:(NSArray *)coverPosts {
    NSMutableArray *posts = [NSMutableArray array];
    for(NCSocialPost *post in coverPosts)
        for(id attachment in post.attachments)
            if([attachment isKindOfClass:[NSURL class]])
                [posts addObject:attachment];
    
    if(![_coverPosts isEqualToArray:posts]) {
        [_swapTimer invalidate];
        _coverPosts = [posts copy];
        _coverIndex = 0;
        
        if([_coverPosts count] > 0) {
            _swapTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(nextCover) userInfo:nil repeats:YES];
            [self nextCover];
        }
    }
}

- (void)nextCover {
    NSURL *nextImageURL = _coverPosts[_coverIndex];
    NSURLRequest *request = [NSURLRequest requestWithURL:nextImageURL];
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(_coverImageView) weakImageView = _coverImageView;
    
    [_coverImageView setImageWithURLRequest:request placeholderImage:_coverImageView.image success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [UIView transitionWithView:weakImageView duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            weakImageView.image = image;
        } completion:nil];
        weakSelf.coverIndex++;
        if(weakSelf.coverIndex >= [weakSelf.coverPosts count]) weakSelf.coverIndex = 0;
    } failure:nil];
}

- (UIImage *)currentImage {
    return _coverImageView.image;
}

@end
