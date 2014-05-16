//
//  NCEfficientTableViewCell.m
//  Newman Knights
//
//  Created by Nick Frey on 5/7/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCEfficientTableViewCell.h"

@interface NCEfficientTableViewCellView ()

@property (nonatomic, weak) NCEfficientTableViewCell *parentCell;

@end

@implementation NCEfficientTableViewCellView

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		self.contentMode = UIViewContentModeRedraw|UIViewContentModeTop;
        self.opaque = YES;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [_parentCell drawCellView:rect];
}

@end

@implementation NCEfficientTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _cellView = [[NCEfficientTableViewCellView alloc] initWithFrame:self.bounds];
        _cellView.parentCell = self;
		[self.contentView addSubview:_cellView];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	_cellView.frame = self.bounds;
}

- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	[_cellView setNeedsDisplay];
}

- (void)setNeedsDisplayInRect:(CGRect)rect {
	[super setNeedsDisplayInRect:rect];
	[_cellView setNeedsDisplayInRect:rect];
}

- (void)drawCellView:(CGRect)rect {
    // Implement in subclasses
}

@end
