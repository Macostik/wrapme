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
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.5;
    __weak typeof(self)weakSelf = self;
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                                        withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                            CMAcceleration acceleration = accelerometerData.acceleration;
                                            UIDeviceOrientation orientation = fabs(acceleration.y) < fabs(acceleration.x) ?
                                            acceleration.x > 0 ? UIDeviceOrientationLandscapeRight  :   UIDeviceOrientationLandscapeLeft :
                                            acceleration.y > 0 ? UIDeviceOrientationPortraitUpsideDown : UIDeviceOrientationPortrait;
                                            if (orientation != [[UIDevice currentDevice] orientation]) {
                                                if (orientation != [weakSelf.orientationFromAccelerometer integerValue]) {
                                                    weakSelf.orientationFromAccelerometer = @(orientation);
                                                    run_in_main_queue(^{
                                                        [weakSelf broadcast:@selector(broadcaster:didChangeOrientation:) object:@(orientation)];
                                                    });
                                                }
                                            }
                                        }];
}

- (void)endUsingAccelerometer {
    [self.motionManager stopAccelerometerUpdates];
    self.motionManager = nil;
    self.orientationFromAccelerometer = nil;
}

@end