//
//  WLBlockDispatch.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBlockDispatch.h"

@implementation WLBlockDispatch

+ (instancetype)dispatch:(WLBlock)block {
    return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(WLBlock)block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

- (void)send {
    WLBlock block = self.block;
    if (block) {
        block();
    }
}

@end
