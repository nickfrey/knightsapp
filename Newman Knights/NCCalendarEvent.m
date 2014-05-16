//
//  NCCalendarEvent.m
//  Newman Knights
//
//  Created by Nick Frey on 4/30/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCCalendarEvent.h"

@implementation NCCalendarEvent

- (BOOL)isEqual:(id)object {
    if([object isKindOfClass:[self class]]) {
        return [self.identifier isEqualToString:[object identifier]];
    } else {
        return [super isEqual:object];
    }
}

@end
