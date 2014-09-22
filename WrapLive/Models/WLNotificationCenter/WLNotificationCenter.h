//
//  WLPubNubBroadcaster.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLBlocks.h"

@class WLNotificationCenter;
@class WLNotification;
@class WLUser;
@class WLWrap;

@protocol WLNotificationReceiver

@optional

- (void)broadcaster:(WLNotificationCenter *)broadcaster notificationReceived:(WLNotification *)notification;

- (BOOL)broadcaster:(WLNotificationCenter *)broadcaster shouldReceiveNotification:(WLNotification *)notification;

- (void)broadcaster:(WLNotificationCenter *)broadcaster didReceiveRemoteNotification:(WLNotification *)notification;

- (void)broadcaster:(WLNotificationCenter *)broadcaster didStoreNotification:(WLNotification *)notification;

- (void)broadcaster:(WLNotificationCenter *)broadcaster didBeginTyping:(WLUser *)user;

- (void)broadcaster:(WLNotificationCenter *)broadcaster didEndTyping:(WLUser *)user;

@end

@interface WLNotificationCenter : WLBroadcaster

@property (strong, nonatomic) WLNotification* pendingRemoteNotification;

+ (instancetype)defaultCenter;

+ (void)setDeviceToken:(NSData*)deviceToken;

+ (void)deviceToken:(WLDataBlock)completion;

- (void)handleRemoteNotification:(NSDictionary*)data;

- (void)connect;

@end

@interface WLNotificationCenter (Typing)

- (void)subscribeOnTypingChannel:(WLWrap *)wrap success:(WLBlock)success;

- (void)unsubscribeFromTypingChannel;

- (BOOL)isSubscribedOnTypingChannel:(WLWrap *)wrap;

- (void)beginTyping;

- (void)endTyping;

@end
