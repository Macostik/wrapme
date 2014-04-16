//
//  WLCircleProgressBar.m
//  WrapLive
//
//  Created by Sergey Maximenko on 16.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCircleProgressBar.h"
#import "WLBorderView.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "NSArray+Additions.h"

@interface WLCircleProgressBar ()

@property (nonatomic, readonly) CAShapeLayer* progressLayer;

@property (weak, nonatomic) UIActivityIndicatorView* spinner;

@end

@implementation WLCircleProgressBar

- (UIView *)initializeBackgroundView {
	UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	backgroundView.clipsToBounds = YES;
	return backgroundView;
}

- (UIView *)initializeProgressViewWithBackgroundView:(UIView *)backgroundView {
	UIView* progressView = [[UIView alloc] initWithFrame:backgroundView.bounds];
	progressView.backgroundColor = [UIColor clearColor];
	progressView.layer.cornerRadius = progressView.height / 2.0f;
	progressView.clipsToBounds = YES;
	
	UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	spinner.center = progressView.centerBoundary;
	spinner.hidesWhenStopped = YES;
	spinner.color = [UIColor WL_orangeColor];
	[progressView addSubview:spinner];
	self.spinner = spinner;
	
	return progressView;
}

- (CGPathRef)progressPath {
	CGPoint center = self.progressView.centerBoundary;
	return [UIBezierPath bezierPathWithArcCenter:center
										  radius:center.x
									  startAngle:3*M_PI_2
										endAngle:(3*M_PI_2 + 2*M_PI*_progress)
									   clockwise:YES].CGPath;
}

- (CAShapeLayer*)progressLayer {
	
	CAShapeLayer* progressLayer = [self.progressView.layer.sublayers selectObject:^BOOL(CALayer* layer) {
		return [layer isKindOfClass:[CAShapeLayer class]];
	}];
	if (!progressLayer) {
		progressLayer = [CAShapeLayer layer];
		progressLayer.frame = self.progressView.bounds;
		progressLayer.fillColor = [UIColor clearColor].CGColor;
		progressLayer.strokeColor = [UIColor WL_orangeColor].CGColor;
		progressLayer.lineWidth = 6;
		progressLayer.masksToBounds = YES;
		[self.progressView.layer addSublayer:progressLayer];
	}
	return progressLayer;
}

- (void)updateProgressViewAnimated:(BOOL)animated difference:(float)difference {
	__weak typeof(self)weakSelf = self;
	CAShapeLayer* layer = weakSelf.progressLayer;
	
	if (_progress == 0 || _progress == 1) {
		[self.spinner startAnimating];
		layer.hidden = YES;
		[layer removeAllAnimations];
	} else {
		[self.spinner stopAnimating];
		layer.hidden = NO;
		CGPathRef fromPath = layer.path;
		CGPathRef toPath = [self progressPath];
		if (animated) {
			CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"path"];
			anim.duration = 0.2;
			anim.fromValue = (__bridge id)fromPath;
			anim.toValue = (__bridge id)toPath;
			[layer addAnimation:anim forKey:nil];
		}
		layer.path = toPath;
	}
}

@end
