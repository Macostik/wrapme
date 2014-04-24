//
//  WLDeviceOrientationBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLDeviceOrientationBroadcaster;

@protocol WLDeviceOrientationBroadcastReceiver <WLBroadcastReceiver>

@optional
- (void)broadcaster:(WLDeviceOrientationBroadcaster*)broadcaster didChangeOrientation:(UIDeviceOrientation)orientation;

@end

@interface WLDeviceOrientationBroadcaster : WLBroadcaster

@end
