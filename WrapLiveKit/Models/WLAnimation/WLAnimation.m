//
//  WLAnimation.m
//  moji
//
//  Created by Ravenpod on 5/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAnimation.h"

@interface WLAnimation ()

@property (nonatomic) BOOL animating;

@property (nonatomic) NSTimeInterval progress;

@property (nonatomic) CGFloat progressRatio;

@property (nonatomic) NSTimeInterval step;

@end

@implementation WLAnimation

+ (instancetype)animationWithDuration:(NSTimeInterval)duration {
    WLAnimation *animation = [[WLAnimation alloc] init];
    animation.duration = duration;
    return animation;
}

- (void)start {
    if (!self.animating) {
        self.animating = YES;
        self.progress = 0;
        self.progressRatio = 0;
        self.step = 1.0f / 26.0f;
        NSTimer *timer = [NSTimer timerWithTimeInterval:self.step target:self selector:@selector(animate:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}

- (void)setView:(UIView *)view {
    _view = view;
    if (view && self.animating) {
        if (self.animationBlock) self.animationBlock(self, view);
    }
}

- (void)animate:(NSTimer*)timer {
    self.progress = Smoothstep(0, self.duration, self.progress + self.step);
    self.progressRatio = NSmoothstep(self.progress / self.duration);
    if (self.animationBlock) self.animationBlock(self, self.view);
    if (self.progressRatio == 1.0f) {
        self.animating = NO;
        [timer invalidate];
        if (self.completionBlock) self.completionBlock();
    }
}

@end
