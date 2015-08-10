//
//  WLDeviceOrientationBroadcaster.h
//  moji
//
//  Created by Ravenpod on 24.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
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
