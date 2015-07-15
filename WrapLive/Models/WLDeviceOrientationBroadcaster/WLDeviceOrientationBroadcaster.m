//
//  WLDeviceOrientationBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLDeviceOrientationBroadcaster.h"
#import <CoreMotion/CoreMotion.h>

@interface WLDeviceOrientationBroadcaster ()

@property (strong, nonatomic) CMMotionManager *motionManager;

@property (strong, nonatomic) NSNumber* orientationFromAccelerometer;

@end

@implementation WLDeviceOrientationBroadcaster

+ (instancetype)broadcaster {
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
    if (orientation == UIDeviceOrientationUnknown && self.orientationFromAccelerometer) {
        orientation = [self.orientationFromAccelerometer integerValue];
    }
    return orientation;
}

- (void)orientationChanged:(NSNotification*)notification {
    [self broadcast:@selector(broadcaster:didChangeOrientation:) object:@([UIDevice currentDevice].orientation)];
}

- (void)beginUsingAccelerometer {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation != UIDeviceOrientationUnknown) {
        return;
    }
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.5;
    __weak typeof(self)weakSelf = self;
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                                        withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                            CMAcceleration acceleration = accelerometerData.acceleration;

                                            UIDeviceOrientation lastOrientation = [weakSelf.orientationFromAccelerometer integerValue];
                                            
                                            float xx = -acceleration.x;
                                            float yy = acceleration.y;
                                            float angle = atan2(yy, xx);
                                            UIDeviceOrientation orientation;
                                            if(angle >= -2.25 && angle <= -0.25) {
                                                orientation = UIDeviceOrientationPortrait;
                                            } else if(angle >= -1.75 && angle <= 0.75) {
                                                orientation = UIDeviceOrientationLandscapeRight;
                                            } else if(angle >= 0.75 && angle <= 2.25) {
                                                orientation = UIDeviceOrientationPortraitUpsideDown;
                                            } else if(angle <= -2.25 || angle >= 2.25) {
                                                orientation = UIDeviceOrientationLandscapeLeft;
                                            }
                                            
                                            if(lastOrientation != orientation) {
                                                lastOrientation = orientation;
                                                weakSelf.orientationFromAccelerometer = @(orientation);
                                                run_in_main_queue(^{
                                                    [weakSelf broadcast:@selector(broadcaster:didChangeOrientation:) object:weakSelf.orientationFromAccelerometer];
                                                });
                                            }
                                        }];
}

- (void)endUsingAccelerometer {
    [self.motionManager stopAccelerometerUpdates];
    self.motionManager = nil;
    self.orientationFromAccelerometer = nil;
}

@end