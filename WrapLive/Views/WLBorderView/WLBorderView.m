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

- (UIColor *)strokeColor {
	if (!_strokeColor) {
		_strokeColor = [UIColor WL_grayColor];
	}
	return _strokeColor;
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
	[[UIBezierPath bezierPathWithRect:self.bounds] stroke];
}

@end
