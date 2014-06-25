//
//  WLBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL (^WLBroadcastSelectReceiver)(id receiver);

@interface WLBroadcaster : NSObject

@property (strong, nonatomic, readonly) NSHashTable* receivers;

+ (instancetype)broadcaster;

- (instancetype)initWithReceiver:(id)receiver;

- (void)setup;

- (void)configure;

- (void)addReceiver:(id)receiver;

- (void)removeReceiver:(id)receiver;

- (BOOL)containsReceiver:(id)receiver;

- (void)broadcast:(SEL)selector object:(id)object;

- (void)broadcast:(SEL)selector object:(id)object select:(WLBroadcastSelectReceiver)select;

- (void)broadcast:(SEL)selector;

- (void)broadcast:(SEL)selector select:(WLBroadcastSelectReceiver)select;

@end
