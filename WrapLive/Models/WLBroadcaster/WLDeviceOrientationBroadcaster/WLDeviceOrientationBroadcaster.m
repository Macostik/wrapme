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
    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
}

- (void)removeReceiver:(id)receiver {
    [super removeReceiver:receiver];
    if ([self.receivers anyObject] == 0) {
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    }
}

- (void)setup {
    [super setup];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)orientationChanged:(NSNotification*)notification {
    if ([self.receivers anyObject] == 0) {
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    } else {
        [self broadcast:@selector(broadcaster:didChangeOrientation:) object:@([UIDevice currentDevice].orientation)];
    }
}

@end