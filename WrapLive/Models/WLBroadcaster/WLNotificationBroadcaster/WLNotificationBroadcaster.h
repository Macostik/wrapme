//
//  WLPubNubBroadcaster.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLNotificationBroadcaster;
@class WLNotification;

@protocol WLNotificationReceiver

@optional

- (void)broadcaster:(WLNotificationBroadcaster *)broadcaster notificationReceived:(WLNotification *)notification;

- (BOOL)broadcaster:(WLNotificationBroadcaster *)broadcaster shouldReceiveNotification:(WLNotification *)notification;

- (void)broadcaster:(WLNotificationBroadcaster *)broadcaster didReceiveRemoteNotification:(WLNotification *)notification;

@end

@interface WLNotificationBroadcaster : WLBroadcaster

@property (strong, nonatomic) WLNotification* pendingRemoteNotification;

+ (void)enablePushNotificationsInChannels:(NSArray*)channels withDeviceToken:(NSData*)deviceToken;

+ (void)enablePushNotificationsInSubscribedChannels:(NSData*)deviceToken;

- (void)handleRemoteNotification:(NSDictionary*)data;

@end
