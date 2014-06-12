//
//  WLGestureBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/11/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLGestureBroadcaster.h"
#import <CoreMotion/CoreMotion.h>

static inline BOOL AccelerationIsShaking(CMAcceleration current, double t) {
    return (current.x > t || current.y > t || current.z > t);
}

static inline BOOL GyroIsRotating(CMRotationRate rotation, double t) {
    return (fabs(rotation.y) > t);
}

@interface WLGestureBroadcaster () <WLGestureBroadcastReceiver>

@property (strong, nonatomic) CMMotionManager *manager;

@property (nonatomic) CMAcceleration acceleration;

@property (strong, nonatomic) NSOperationQueue *queue;

@property (nonatomic) NSUInteger shakeCount;

@end

@implementation WLGestureBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (CMMotionManager *)manager {
    if (!_manager) {
        _manager = [[CMMotionManager alloc] init];
    }
    return _manager;
}

- (NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
    }
    return _queue;
}

- (void)setShaking:(BOOL)shaking {
    if (_shaking != shaking) {
        _shaking = shaking;
        if (shaking) {
            self.shakeCount++;
            if (self.shakeCount >= 2) {
                self.shakeCount = 0;
                [self broadcast:@selector(broadcasterDidShake:)];
            }
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetShakeCount) object:nil];
            [self performSelector:@selector(resetShakeCount) withObject:nil afterDelay:1];
        }
    }
}

- (void)resetShakeCount {
    self.shakeCount = 0;
}

- (void)setRotating:(BOOL)rotating {
    if (_rotating != rotating) {
        _rotating = rotating;
        if (rotating) {
            [self broadcast:@selector(broadcasterDidRotate:)];
        }
    }
}

- (void)setup {
    [self addReceiver:self];
    __weak typeof(self)weakSelf = self;
    [self.manager startAccelerometerUpdatesToQueue:self.queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        if (!error) {
            CMAcceleration acceleration = accelerometerData.acceleration;
            weakSelf.shaking = AccelerationIsShaking(acceleration, 2.5);
            weakSelf.acceleration = acceleration;
        }
    }];
    
    [self.manager startGyroUpdatesToQueue:self.queue withHandler:^(CMGyroData *gyroData, NSError *error) {
        weakSelf.rotating = GyroIsRotating(gyroData.rotationRate, 20);
    }];
}

- (void)broadcasterDidShake:(WLGestureBroadcaster *)broadcaster {
    NSLog(@"shake");
}

- (void)broadcasterDidStopShaking:(WLGestureBroadcaster *)broadcaster {
}

- (void)broadcasterDidRotate:(WLGestureBroadcaster *)broadcaster {
    NSLog(@"rotate");
}

@end
