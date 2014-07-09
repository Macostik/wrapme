//
//  WLDeviceOrientationBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLDeviceOrientationBroadcaster.h"

@implementation WLDeviceOrientationBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (void)addReceiver:(id)receiver {
    [super addReceiver:receiver];
}

- (void)removeReceiver:(id)receiver {
    [super removeReceiver:receiver];
}

- (void)setup {
    [super setup];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    });
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)orientationChanged:(NSNotification*)notification {
    [self broadcast:@selector(broadcaster:didChangeOrientation:) object:@([UIDevice currentDevice].orientation)];
}

@end