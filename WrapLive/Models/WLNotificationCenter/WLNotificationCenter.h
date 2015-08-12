//
//  WLPubNubBroadcaster.h
//  moji
//
//  Created by Ravenpod on 5/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

@interface WLNotificationCenter : NSObject

+ (instancetype)defaultCenter;

- (void)clear;

- (void)configure;

- (void)handleRemoteNotification:(NSDictionary*)data success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)subscribe;

@end
