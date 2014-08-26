//
//  WLBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import <objc/message.h>
#import "WLSupportFunctions.h"

@interface WLBroadcaster ()

@property (strong, nonatomic) NSHashTable* receivers;

@end

@implementation WLBroadcaster

+ (instancetype)broadcaster {
    return nil;
}

- (instancetype)initWithReceiver:(id)receiver {
    self = [self init];
    if (self) {
        [self addReceiver:receiver];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
	self.receivers = [NSHashTable weakObjectsHashTable];
}

- (void)configure {
	
}

- (void)addReceiver:(id)receiver {
	[self.receivers addObject:receiver];
}

- (void)removeReceiver:(id)receiver {
	[self.receivers removeObject:receiver];
}

- (BOOL)containsReceiver:(id)receiver {
	return [self.receivers containsObject:receiver];
}

- (void)broadcast:(SEL)selector object:(id)object {
	[self broadcast:selector object:object select:nil];
}

- (void)broadcast:(SEL)selector object:(id)object select:(WLBroadcastSelectReceiver)select {
    NSHashTable* receivers = [self.receivers copy];
    @synchronized (receivers) {
        for (id receiver in receivers) {
            if ((select ? select(receiver, object) : YES) && [receiver respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [receiver performSelector:selector withObject:self withObject:object];
#pragma clang diagnostic pop
            }
        }
    }
}

- (void)broadcast:(SEL)selector {
	[self broadcast:selector select:nil];
}

- (void)broadcast:(SEL)selector select:(WLBroadcastSelectReceiver)select {
    [self broadcast:selector object:nil select:select];
}

@end
