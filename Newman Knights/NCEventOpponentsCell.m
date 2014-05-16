//
//  NCEventOpponentsCell.m
//  Newman Knights
//
//  Created by Nick Frey on 5/7/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCEventOpponentsCell.h"

@interface NCEventOpponentsCell ()

@property (nonatomic, strong) NSDictionary *titleAttributes;
@property (nonatomic, strong) NSDictionary *detailAttributes;
@property (nonatomic) UIEdgeInsets contentInsets;
@property (nonatomic) CGFloat lineSpacing;

@end

@implementation NCEventOpponentsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.cellView.backgroundColor = [UIColor whiteColor];
        
        _titleAttributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
        _detailAttributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline], NSForegroundColorAttributeName: [UIColor colorWithWhite:0.5 alpha:1]};
        _contentInsets = UIEdgeInsetsMake(15, 15, 15, 15);
        _lineSpacing = 10;
    }
    return self;
}

- (CGFloat)heightForCalendarEvent:(NCCalendarEvent *)event {
    CGFloat width = self.frame.size.width - _contentInsets.left - _contentInsets.right;
    CGFloat y = _contentInsets.top;
    
    /* Title */
    NSString *title = NSLocalizedString(@"Opponents", @"Opponents");
    CGRect titleRect = [title boundingRectWithSize:CGSizeMake(width, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:_titleAttributes context:nil];
    y += titleRect.size.height + _lineSpacing;
    
    /* Opponents */
    NSString *opponents = [event.opponents componentsJoinedByString:@"\n"];
    CGRect opponentsRect = [opponents boundingRectWithSize:CGSizeMake(width, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:_detailAttributes context:nil];
    y += opponentsRect.size.height + _contentInsets.bottom;
    
    return y;
}

- (void)drawCellView:(CGRect)rect {
    CGFloat width = self.frame.size.width - _contentInsets.left - _contentInsets.right;
    CGFloat y = _contentInsets.top;
    
    /* Title */
    NSString *title = NSLocalizedString(@"Opponents", @"Opponents");
    CGRect titleRect = [title boundingRectWithSize:CGSizeMake(width, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:_titleAttributes context:nil];
    [title drawInRect:CGRectMake(_contentInsets.left, y, titleRect.size.width, titleRect.size.height) withAttributes:_titleAttributes];
    y += titleRect.size.height + _lineSpacing;
    
    /* Opponents */
    NSString *opponents = [_event.opponents componentsJoinedByString:@"\n"];
    CGRect opponentsRect = [opponents boundingRectWithSize:CGSizeMake(width, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:_detailAttributes context:nil];
    [opponents drawInRect:CGRectMake(_contentInsets.left, y, opponentsRect.size.width, opponentsRect.size.height) withAttributes:_detailAttributes];
}

@end
