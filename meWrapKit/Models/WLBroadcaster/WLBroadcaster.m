//
//  WLBroadcaster.m
//  meWrap
//
//  Created by Ravenpod on 24.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBroadcaster.h"

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
    if ([receiver respondsToSelector:@selector(broadcasterOrderPriority:)]) {
        self.prioritize = YES;
    }
}

- (void)removeReceiver:(id)receiver {
    [self.receivers removeObject:receiver];
}

- (BOOL)containsReceiver:(id)receiver {
	return [self.receivers containsObject:receiver];
}

- (NSArray *)sortedReceivers {
    
    NSComparator comparator = ^NSComparisonResult(id <WLBroadcastReceiver> obj1, id <WLBroadcastReceiver> obj2) {
        NSInteger first = WLBroadcastReceiverOrderPriorityDefault;
        NSInteger second = first;
        if ([obj1 respondsToSelector:@selector(broadcasterOrderPriority:)]) {
            first = [obj1 broadcasterOrderPriority:self];
        }
        if ([obj2 respondsToSelector:@selector(broadcasterOrderPriority:)]) {
            second = [obj2 broadcasterOrderPriority:self];
        }
        if (first < second) {
            return NSOrderedAscending;
        } else if (first > second) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    };
    
    return [[self.receivers allObjects] sortedArrayUsingComparator:comparator];
}

- (void)broadcast:(SEL)selector object:(id)object {
	[self broadcast:selector object:object select:nil];
}

- (void)broadcast:(SEL)selector object:(id)object select:(WLBroadcastSelectReceiver)select {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSArray *receivers = nil;
    if (self.prioritize) {
        receivers = [self sortedReceivers];
    } else {
        receivers = [self.receivers copy];
    }
    for (id receiver in receivers) {
        if ((select ? select(receiver, object) : YES) && [receiver respondsToSelector:selector]) {
            [receiver performSelector:selector withObject:self withObject:object];
        }
    }
#pragma clang diagnostic pop
}

- (void)broadcast:(SEL)selector {
	[self broadcast:selector select:nil];
}

- (void)broadcast:(SEL)selector select:(WLBroadcastSelectReceiver)select {
    [self broadcast:selector object:nil select:select];
}

@end
