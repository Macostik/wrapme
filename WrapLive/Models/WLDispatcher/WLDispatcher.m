//
//  WLDispatcher.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDispatcher.h"

@implementation WLDispatcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.receivers = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (void)addReceiver:(id)receiver dispatch:(WLDispatch *)dispatch {
    [self.receivers setObject:dispatch forKey:receiver];
}

- (void)addReceiver:(id)receiver selector:(SEL)selector {
    [self addReceiver:receiver dispatch:[WLDispatch dispatch:receiver selector:selector]];
}

- (void)addReceiver:(id)receiver block:(WLBlock)block {
    [self addReceiver:receiver dispatch:[WLBlockDispatch dispatch:block]];
}

- (void)send {
    NSMapTable* receivers = self.receivers;
    for (id key in receivers) {
        [[receivers objectForKey:key] send];
    }
}

@end
