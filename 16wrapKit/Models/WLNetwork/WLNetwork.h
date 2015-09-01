//
//  WLNetwork.h
//  moji
//
//  Created by Ravenpod on 5/7/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLNetwork;

@protocol WLNetworkReceiver

@optional
- (void)networkDidChangeReachability:(WLNetwork *)network;

@end

@interface WLNetwork : WLBroadcaster

@property (nonatomic, readonly) BOOL reachable;

@property (strong, nonatomic) void (^changeReachabilityBlock) (WLNetwork *network);

+ (instancetype)network;

@end
