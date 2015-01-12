//
//  WLPubNubBroadcaster.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLNotificationCenter;
@class WLNotification;
@class WLUser;
@class WLWrap;

@interface WLNotificationCenter : WLBroadcaster

+ (instancetype)defaultCenter;

+ (void)setDeviceToken:(NSData*)deviceToken;

+ (void)deviceToken:(WLDataBlock)completion;

- (void)handleRemoteNotification:(NSDictionary*)data success:(WLBlock)success failure:(WLFailureBlock)failure;

- (void)subscribe;

@end
