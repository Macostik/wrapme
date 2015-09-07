//
//  NSObject+Extension.m
//  meWrap
//
//  Created by Ravenpod on 8/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSObject+Extension.h"

@implementation NSObject (Extension)

- (void)enqueueSelectorPerforming:(SEL)aSelector {
    [self enqueueSelectorPerforming:aSelector afterDelay:0.5f];
}

- (void)enqueueSelectorPerforming:(SEL)aSelector afterDelay:(NSTimeInterval)delay {
    [self enqueueSelectorPerforming:aSelector withObject:nil afterDelay:delay];
}

- (void)enqueueSelectorPerforming:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:aSelector object:anArgument];
    [self performSelector:aSelector withObject:anArgument afterDelay:delay];
}

@end
