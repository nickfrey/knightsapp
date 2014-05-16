//
//  NCEfficientTableViewCell.h
//  Newman Knights
//
//  Created by Nick Frey on 5/7/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCEfficientTableViewCellView : UIView

@end

@interface NCEfficientTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) NCEfficientTableViewCellView *cellView;

- (void)drawCellView:(CGRect)rect;

@end
