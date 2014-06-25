//
//  WLGestureBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/11/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLGestureBroadcaster;

@protocol WLGestureBroadcastReceiver

@optional

- (void)broadcasterDidShake:(WLGestureBroadcaster*)broadcaster;
- (void)broadcasterDidRotate:(WLGestureBroadcaster*)broadcaster;

@end

@interface WLGestureBroadcaster : WLBroadcaster

@property (nonatomic) BOOL shaking;

@property (nonatomic) BOOL rotating;

@end
