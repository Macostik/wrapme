//
//  WLBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WLBroadcastReceiver <NSObject>

@end

typedef BOOL (^WLBroadcastSelectReceiver)(NSObject <WLBroadcastReceiver> *receiver);

@interface WLBroadcaster : NSObject

@property (strong, nonatomic, readonly) NSHashTable* receivers;

+ (instancetype)broadcaster;

- (instancetype)initWithReceiver:(id <WLBroadcastReceiver>)receiver;

- (void)setup;

- (void)configure;

- (void)addReceiver:(id <WLBroadcastReceiver>)receiver;

- (void)removeReceiver:(id <WLBroadcastReceiver>)receiver;

- (BOOL)containsReceiver:(id <WLBroadcastReceiver>)receiver;

- (void)broadcast:(SEL)selector object:(id)object;

- (void)broadcast:(SEL)selector object:(id)object select:(WLBroadcastSelectReceiver)select;

- (void)broadcast:(SEL)selector;

- (void)broadcast:(SEL)selector select:(WLBroadcastSelectReceiver)select;

@end
