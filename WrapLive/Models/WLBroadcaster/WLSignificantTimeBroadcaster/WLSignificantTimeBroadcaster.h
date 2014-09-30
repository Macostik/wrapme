//
//  WLSignificantTimeBroadcaster.h
//  WrapLive
//
//  Created by Yura Granchenko on 7/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDeviceOrientationBroadcaster.h"

@protocol WlSignificantTimeBroadcasterReceiver;

@interface WLSignificantTimeBroadcaster : WLBroadcaster

@end

@protocol WlSignificantTimeBroadcasterReceiver <NSObject>

@optional

- (void)broadcaster:(WLSignificantTimeBroadcaster *)broadcaster didChangeSignificantTime:(id)object;

@end
