//
//  WLBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import <objc/message.h>

@interface WLBroadcaster ()

@property (strong, nonatomic) NSHashTable* receivers;

@end

@implementation WLBroadcaster {
    BOOL broadcasting;
}

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
    if (!broadcasting) {
        [self.receivers addObject:receiver];
    } else {
        [self.receivers performSelector:@selector(addObject:) withObject:receiver afterDelay:0.0f];
    }
}

- (void)removeReceiver:(id)receiver {
    if (!broadcasting) {
        [self.receivers removeObject:receiver];
    } else {
        [self.receivers performSelector:@selector(removeObject:) withObject:receiver afterDelay:0.0f];
    }
}

- (BOOL)containsReceiver:(id)receiver {
	return [self.receivers containsObject:receiver];
}

- (void)broadcast:(SEL)selector object:(id)object {
	[self broadcast:selector object:object select:nil];
}

- (void)broadcast:(SEL)selector object:(id)object select:(WLBroadcastSelectReceiver)select {
    broadcasting = YES;
    for (id receiver in self.receivers) {
        if ((select ? select(receiver, object) : YES) && [receiver respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [receiver performSelector:selector withObject:self withObject:object];
#pragma clang diagnostic pop
        }
    }
    broadcasting = NO;
}

- (void)broadcast:(SEL)selector {
	[self broadcast:selector select:nil];
}

- (void)broadcast:(SEL)selector select:(WLBroadcastSelectReceiver)select {
    [self broadcast:selector object:nil select:select];
}

@end
