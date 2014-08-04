//
//  WLInternetConnectionBroadcaster.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/7/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import <Reachability/Reachability.h>

@class WLInternetConnectionBroadcaster;

@protocol WLInternetConnectionBroadcastReceiver

@optional
- (void)broadcaster:(WLInternetConnectionBroadcaster *)broadcaster internetConnectionReachable:(NSNumber *)reachable;

@end

@interface WLInternetConnectionBroadcaster : WLBroadcaster

@property (nonatomic, readonly) BOOL reachable;

@end
