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

@interface WLBroadcaster : NSObject

@property (strong, nonatomic, readonly) NSHashTable* receivers;

+ (instancetype)broadcaster;

- (void)addReceiver:(id <WLBroadcastReceiver>)receiver;

- (BOOL)containsReceiver:(id <WLBroadcastReceiver>)receiver;

- (void)broadcast:(SEL)selector object:(id)object;

- (void)broadcast:(SEL)selector;

@end
