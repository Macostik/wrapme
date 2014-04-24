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

- (instancetype)init {
    self = [super init];
    if (self) {
        [self subscribeKeyboardNotifications];
    }
    return self;
}

- (void)subscribeKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)orientationChanged:(NSNotification*)notification {
	for (id <WLDeviceOrientationBroadcastReceiver> receiver in self.receivers) {
		if ([receiver respondsToSelector:@selector(broadcaster:didChangeOrientation:)]) {
			[receiver broadcaster:self didChangeOrientation:[UIDevice currentDevice].orientation];
		}
	}
}

@end
