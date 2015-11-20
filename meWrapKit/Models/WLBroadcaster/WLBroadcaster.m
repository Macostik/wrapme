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

- (id<NSFastEnumeration>)broadcastReceivers {
    return self.prioritize ? [self sortedReceivers] : [self.receivers copy];
}

- (void)broadcast:(void (^)(id))block {
    for (id receiver in [self broadcastReceivers]) {
        block(receiver);
    }
}

@end
