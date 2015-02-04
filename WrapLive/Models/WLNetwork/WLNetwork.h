//
//  WLNetwork.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/7/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLNetwork;

@protocol WLNetworkReceiver

@optional
- (void)networkDidChangeReachability:(WLNetwork *)network;

@end

@interface WLNetwork : WLBroadcaster

@property (nonatomic, readonly) BOOL reachable;

+ (instancetype)network;

@end
