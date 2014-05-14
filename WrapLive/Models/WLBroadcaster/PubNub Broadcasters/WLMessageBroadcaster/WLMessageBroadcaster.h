//
//  WLPubNubBroadcaster.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLMessageBroadcaster;

@protocol WLMessageBroadcastReceiver <WLBroadcastReceiver>

- (NSString*)broadcasterChannelName:(WLMessageBroadcaster *)broadcaster;

@optional
- (void)broadcaster:(WLMessageBroadcaster *)broadcaster messageReceived:(PNMessage *)message;

@end

@interface WLMessageBroadcaster : WLBroadcaster

+ (void)enablePushNotificationsInChannels:(NSArray*)channels withDeviceToken:(NSData*)deviceToken;

- (void)unsubscribe:(id<WLMessageBroadcastReceiver>)receiver;

- (void)subscribe:(id<WLMessageBroadcastReceiver>)receiver;

- (void)addReceiver:(id<WLMessageBroadcastReceiver>)receiver;

@end
