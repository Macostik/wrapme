//
//  WLPubNubBroadcaster.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLNotificationCenter;

@interface WLNotificationCenter : WLBroadcaster

@property (strong, nonatomic) void (^gettingDeviceTokenBlock) (WLDataBlock gettingDeviceTokenCompletionBlock);

+ (instancetype)defaultCenter;

- (void)handleRemoteNotification:(NSDictionary*)data success:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)subscribe;

- (void)deviceToken:(WLDataBlock)completion;

@end
