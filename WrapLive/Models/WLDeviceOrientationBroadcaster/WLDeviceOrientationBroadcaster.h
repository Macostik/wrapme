//
//  WLDeviceOrientationBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLDeviceOrientationBroadcaster;

@protocol WLDeviceOrientationBroadcastReceiver

@optional
- (void)broadcaster:(WLDeviceOrientationBroadcaster*)broadcaster didChangeOrientation:(NSNumber*)orientation;

@end

@interface WLDeviceOrientationBroadcaster : WLBroadcaster

@property (readonly, nonatomic) UIDeviceOrientation orientation;

- (void)beginUsingAccelerometer;

- (void)endUsingAccelerometer;

@end
