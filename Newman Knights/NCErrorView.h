//
//  NCErrorView.h
//  Newman Knights
//
//  Created by Nick Frey on 3/14/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NCErrorView;

@protocol NCErrorViewDelegate <NSObject>

- (void)errorViewDidRequestRetry:(NCErrorView *)errorView;

@end

@interface NCErrorView : UIView

@property (nonatomic, weak) id <NCErrorViewDelegate> delegate;
@property (nonatomic, strong) NSString *errorMessage;

@end
