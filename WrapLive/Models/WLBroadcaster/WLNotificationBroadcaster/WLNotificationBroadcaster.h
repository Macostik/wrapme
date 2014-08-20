//
//  WLPubNubBroadcaster.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLBlocks.h"

@class WLNotificationBroadcaster;
@class WLNotification;
@class WLUser;
@class WLWrap;

@protocol WLNotificationReceiver

@optional

- (void)broadcaster:(WLNotificationBroadcaster *)broadcaster notificationReceived:(WLNotification *)notification;

- (BOOL)broadcaster:(WLNotificationBroadcaster *)broadcaster shouldReceiveNotification:(WLNotification *)notification;

- (void)broadcaster:(WLNotificationBroadcaster *)broadcaster didReceiveRemoteNotification:(WLNotification *)notification;

- (void)broadcaster:(WLNotificationBroadcaster *)broadcaster didBeginTyping:(WLUser *)user;

- (void)broadcaster:(WLNotificationBroadcaster *)broadcaster didEndTyping:(WLUser *)user;

@end

@interface WLNotificationBroadcaster : WLBroadcaster

@property (strong, nonatomic) WLNotification* pendingRemoteNotification;

+ (void)enablePushNotifications;

+ (void)disablePushNotifications;

+ (void)setDeviceToken:(NSData*)deviceToken;

- (void)handleRemoteNotification:(NSDictionary*)data;

- (void)connect;

@end

@interface WLNotificationBroadcaster (Typing)

- (void)subscribeOnTypingChannel:(WLWrap *)wrap success:(WLBlock)success;

- (void)unsubscribeFromTypingChannel;

- (BOOL)isSubscribedOnTypingChannel:(WLWrap *)wrap;

- (void)beginTyping;

- (void)endTyping;

@end
