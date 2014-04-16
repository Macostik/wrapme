//
//  WLBorderView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBorderView.h"
#import "UIColor+CustomColors.h"

@implementation WLBorderView

@synthesize strokeColor = _strokeColor;
@synthesize lineWidth = _lineWidth;

- (UIColor *)strokeColor {
	if (!_strokeColor) {
		_strokeColor = [UIColor WL_grayColor];
	}
	return _strokeColor;
}

- (void)setStrokeColor:(UIColor *)strokeColor {
	_strokeColor = strokeColor;
	[self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth {
	_lineWidth = lineWidth;
	[self setNeedsDisplay];
}

- (CGFloat)lineWidth {
	if (_lineWidth == 0) {
		_lineWidth = 1;
	}
	return _lineWidth;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	[self.strokeColor setStroke];
	UIBezierPath* path = [UIBezierPath bezierPathWithRect:self.bounds];
	path.lineWidth = self.lineWidth;
	[path stroke];
}

@end
