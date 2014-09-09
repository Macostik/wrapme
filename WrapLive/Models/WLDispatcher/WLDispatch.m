//
//  WLDispatch.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDispatch.h"

@implementation WLDispatch

+ (instancetype)dispatch:(id)target selector:(SEL)selector {
    return [[self alloc] initWithTarget:target selector:selector];
}

- (instancetype)initWithTarget:(id)target selector:(SEL)selector {
    self = [super init];
    if (self) {
        self.target = target;
        self.selector = selector;
    }
    return self;
}

- (void)send {
    if (self.target) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
       [self.target performSelector:self.selector];
#pragma clang diagnostic pop
        
    }
}

@end
