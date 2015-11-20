//
//  WLDeviceManager.m
//  meWrap
//
//  Created by Ravenpod on 24.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDeviceManager.h"
#import <CoreMotion/CoreMotion.h>

@interface WLDeviceManager ()

@property (strong, nonatomic) CMMotionManager *motionManager;

@property (strong, nonatomic) NSNumber* orientationFromAccelerometer;

@end

@implementation WLDeviceManager

+ (instancetype)defaultManager {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (void)setup {
    [super setup];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    });
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (UIDeviceOrientation)orientation {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (self.orientationFromAccelerometer) {
        orientation = [self.orientationFromAccelerometer integerValue];
    }
    return orientation;
}

- (void)orientationChanged:(NSNotification*)notification {
    self.orientationFromAccelerometer = nil;
    for (id receiver in [self broadcastReceivers]) {
        if ([receiver respondsToSelector:@selector(manager:didChangeOrientation:)]) {
            [receiver manager:self didChangeOrientation:@([UIDevice currentDevice].orientation)];
        }
    }
}

- (void)beginUsingAccelerometer {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation != UIDeviceOrientationUnknown) {
        self.orientationFromAccelerometer = @(orientation);
    }
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.5;
    __weak typeof(self)weakSelf = self;
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                            [weakSelf handleAcceleration:accelerometerData.acceleration];
                                        }];
}

- (void)handleAcceleration:(CMAcceleration)acceleration {
    UIDeviceOrientation lastOrientation = [self.orientationFromAccelerometer integerValue];
    UIDeviceOrientation orientation = lastOrientation;
    if (acceleration.x >= 0.75) {
        orientation = UIDeviceOrientationLandscapeRight;
    } else if (acceleration.x <= -0.75) {
        orientation = UIDeviceOrientationLandscapeLeft;
    } else if (acceleration.y <= -0.75) {
        orientation = UIDeviceOrientationPortrait;
    } else if (acceleration.y >= 0.75) {
        orientation = UIDeviceOrientationPortraitUpsideDown;
    }
    if(lastOrientation != orientation) {
        self.orientationFromAccelerometer = @(orientation);
        __weak typeof(self)weakSelf = self;
        run_in_main_queue(^{
            for (id receiver in [weakSelf broadcastReceivers]) {
                if ([receiver respondsToSelector:@selector(manager:didChangeOrientation:)]) {
                    [receiver manager:weakSelf didChangeOrientation:weakSelf.orientationFromAccelerometer];
                }
            }
        });
    }
}

- (void)endUsingAccelerometer {
    [self.motionManager stopAccelerometerUpdates];
    self.motionManager = nil;
    self.orientationFromAccelerometer = nil;
}

@end