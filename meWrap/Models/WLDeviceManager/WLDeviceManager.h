//
//  WLDeviceManager.h
//  meWrap
//
//  Created by Ravenpod on 24.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLDeviceManager;

@protocol WLDeviceOrientationBroadcastReceiver

@optional
- (void)manager:(WLDeviceManager*)manager didChangeOrientation:(NSNumber*)orientation;

@end

@interface WLDeviceManager : WLBroadcaster

@property (readonly, nonatomic) UIDeviceOrientation orientation;

+ (instancetype)manager;

- (void)beginUsingAccelerometer;

- (void)endUsingAccelerometer;

@end
