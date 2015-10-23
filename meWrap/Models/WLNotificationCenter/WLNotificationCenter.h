//
//  WLPubNubBroadcaster.h
//  meWrap
//
//  Created by Ravenpod on 5/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

@class WLNotificationSubscription;

@interface WLNotificationCenter : NSObject

@property (strong, nonatomic) NSData *pushToken;

@property (strong, nonatomic) NSString *pushTokenString;

@property (strong, nonatomic, readonly) WLNotificationSubscription* userSubscription;

+ (instancetype)defaultCenter;

- (void)handleDeviceToken:(NSData*)deviceToken;

- (void)clear;

- (void)configure;

- (void)handleRemoteNotification:(NSDictionary*)data success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)subscribe;

@end
