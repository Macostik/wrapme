//
//  WLBroadcaster.h
//  meWrap
//
//  Created by Ravenpod on 24.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLBroadcaster;

static const NSInteger WLBroadcastReceiverOrderPriorityDefault = 0;
static const NSInteger WLBroadcastReceiverOrderPriorityPrimary = -1;
static const NSInteger WLBroadcastReceiverOrderPrioritySecondary = 1;

@protocol WLBroadcastReceiver <NSObject>
@optional
- (NSInteger)broadcasterOrderPriority:(WLBroadcaster *)broadcaster;

@end

typedef BOOL (^WLBroadcastSelectReceiver)(id receiver, id object);

@interface WLBroadcaster : NSObject

@property (strong, nonatomic, readonly) NSHashTable* receivers;

@property (nonatomic) BOOL prioritize;

- (NSArray*)sortedReceivers;

- (void)setup;

- (void)configure;

- (void)addReceiver:(id)receiver;

- (void)removeReceiver:(id)receiver;

- (BOOL)containsReceiver:(id)receiver;

- (id <NSFastEnumeration>)broadcastReceivers;

- (void)broadcast:(void (^)(id receiver))block;

@end
