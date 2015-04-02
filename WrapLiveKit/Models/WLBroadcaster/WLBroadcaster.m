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

- (NSArray *)sortedReceivers {
    
    NSComparator comparator = ^NSComparisonResult(id <WLBroadcastReceiver> obj1, id <WLBroadcastReceiver> obj2) {
        NSNumber *first = @(0);
        NSNumber *second = first;
        if ([obj1 respondsToSelector:@selector(peferedOrderEntry:)]) {
            first = [obj1 peferedOrderEntry:self];
        }
        if ([obj2 respondsToSelector:@selector(peferedOrderEntry:)]) {
            second = [obj2 peferedOrderEntry:self];
        }
        return [first compare:second];
    };
    
    return [[self.receivers allObjects] sortedArrayUsingComparator:comparator];
}

- (void)broadcast:(SEL)selector object:(id)object {
	[self broadcast:selector object:object select:nil];
}

- (void)broadcast:(SEL)selector object:(id)object select:(WLBroadcastSelectReceiver)select {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSArray *receivers = [self sortedReceivers];
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
