//
//  PGCameraInteractionView.m
//  Pressgram
//
//  Created by Sergey Maximenko on 13.02.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import "WLCameraInteractionView.h"
#import "WLCameraAdjustmentView.h"
#import "UIColor+CustomColors.h"

@interface WLCameraInteractionView ()

@property (nonatomic, strong) WLCameraAdjustmentView* focusView;
@property (nonatomic, strong) WLCameraAdjustmentView* exposureView;
@property (nonatomic, strong) WLCameraAdjustmentView* combinedView;

@end

@implementation WLCameraInteractionView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.multipleTouchEnabled = YES;
    self.focusView.multipleTouchEnabled = YES;
    self.focusView.hidden = YES;
    self.exposureView.multipleTouchEnabled = YES;
    self.exposureView.hidden = YES;
    self.combinedView.multipleTouchEnabled = YES;
    self.combinedView.hidden = YES;
}

- (WLCameraAdjustmentView *)focusView {
    if (!_focusView) {
        _focusView = [[WLCameraAdjustmentView alloc] initWithFrame:CGRectMake(0, 0, 67, 67)];
        _focusView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
        _focusView.userInteractionEnabled = NO;
        _focusView.type = WLCameraAdjustmentTypeFocus;
        [self addSubview:_focusView];
    }
    return _focusView;
}

- (WLCameraAdjustmentView *)exposureView {
    if (!_exposureView) {
        _exposureView = [[WLCameraAdjustmentView alloc] initWithFrame:CGRectMake(0, 0, 67, 67)];
        _exposureView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
        _exposureView.userInteractionEnabled = NO;
        _exposureView.type = WLCameraAdjustmentTypeExposure;
        [self addSubview:_exposureView];
    }
    return _exposureView;
}

- (WLCameraAdjustmentView *)combinedView {
    if (!_combinedView) {
        _combinedView = [[WLCameraAdjustmentView alloc] initWithFrame:CGRectMake(0, 0, 67, 67)];
        _combinedView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
        _combinedView.userInteractionEnabled = NO;
        [self addSubview:_combinedView];
    }
    return _combinedView;
}

- (void)setCenter:(CGPoint)center forView:(UIView*)view {
    
    CGFloat minX = view.frame.size.width/2.0f;
    CGFloat minY = view.frame.size.height/2.0f;
    CGFloat maxX = self.frame.size.width - view.frame.size.width/2.0f;
    CGFloat maxY = self.frame.size.height - view.frame.size.width/2.0f;
    
    center.x = Smoothstep(minX, maxX, center.x);
	center.y = Smoothstep(minY, maxY, center.y);
    
    view.center = center;
}

- (UIView*)nearestViewToPoint:(CGPoint)point {
    UIView* nearestView = nil;
    for (WLCameraAdjustmentView* view in self.subviews) {
        if (!view.hidden) {
            if (!nearestView) {
                nearestView = view;
            } else if (CGPointDistanceToPoint(view.center,point) < CGPointDistanceToPoint(nearestView.center,point)) {
                nearestView = view;
            }
        }
    }
    return nearestView;
}

- (void)setCenterToNearestView:(CGPoint)center {
    [self setCenter:center forView:[self nearestViewToPoint:center]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if ([touches count] > 1) {
        self.combinedView.hidden = YES;
        self.focusView.hidden = NO;
        self.exposureView.hidden = NO;
    } else if (self.combinedView.hidden && self.focusView.hidden) {
        self.combinedView.hidden = NO;
    }
	
	[UIView beginAnimations:nil context:nil];
	for (UITouch* touch in touches) {
		[self setCenterToNearestView:[touch locationInView:self]];
	}
	[UIView commitAnimations];
    
    [self sendUpdates];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if ([touches count] > 1) {
        self.combinedView.hidden = YES;
        self.focusView.hidden = NO;
        self.exposureView.hidden = NO;
    } else if (self.combinedView.hidden && self.focusView.hidden) {
        self.combinedView.hidden = NO;
    }
	
    for (UITouch* touch in touches) {
        [self setCenterToNearestView:[touch locationInView:self]];
    }
    
    [self sendUpdates];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.focusView.hidden) {
        if (CGRectContainsPoint(self.focusView.frame, self.exposureView.center)) {
            self.combinedView.hidden = NO;
            self.focusView.hidden = YES;
            self.exposureView.hidden = YES;
            [self setCenter:self.focusView.center forView:self.combinedView];
        }
    }
    
    [self sendUpdates];
}

- (void)sendUpdates {
    
    CGPoint focus;
    CGPoint exposure;
    
    if (!self.combinedView.hidden) {
        focus = self.combinedView.center;
        exposure = self.combinedView.center;
    } else {
        focus = self.focusView.center;
        exposure = self.exposureView.center;
    }
    
    [self.delegate cameraInteractionView:self didChangeFocus:focus];
    [self.delegate cameraInteractionView:self didChangeExposure:exposure];
}

- (void)hideViews {
	__weak WLCameraInteractionView* selfWeak = self;
	[UIView animateWithDuration:0.2 animations:^{
		selfWeak.combinedView.alpha = 0;
		selfWeak.focusView.alpha = 0;
		selfWeak.exposureView.alpha = 0;
	} completion:^(BOOL finished) {
		selfWeak.combinedView.hidden = YES;
		selfWeak.focusView.hidden = YES;
		selfWeak.exposureView.hidden = YES;
		selfWeak.combinedView.alpha = 1;
		selfWeak.focusView.alpha = 1;
		selfWeak.exposureView.alpha = 1;
	}];
}

@end
