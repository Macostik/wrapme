//
//  WLPubNubBroadcaster.h
//  meWrap
//
//  Created by Ravenpod on 5/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

@interface WLNotificationCenter : NSObject

@property (strong, nonatomic) NSData *pushToken;

+ (instancetype)defaultCenter;

- (void)clear;

- (void)configure;

- (void)handleRemoteNotification:(NSDictionary*)data success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)subscribe;

@end
