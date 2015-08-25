//
//  PGSeparatorView.m
//  moji
//
//  Created by Ravenpod on 30.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import "WLSeparatorView.h"

@interface WLSeparatorView ()

@end

@implementation WLSeparatorView

- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGSize size = self.frame.size;
	if (self.contentMode == UIViewContentModeTop) {
		CGContextMoveToPoint(ctx, 0, 0);
		CGContextAddLineToPoint(ctx, size.width, 0);
	} else if (self.contentMode == UIViewContentModeLeft) {
		CGContextMoveToPoint(ctx, 0, 0);
		CGContextAddLineToPoint(ctx, 0, size.height);
	} else if (self.contentMode == UIViewContentModeRight) {
		CGContextMoveToPoint(ctx, size.width, 0);
		CGContextAddLineToPoint(ctx, size.width, size.height);
	} else {
		CGContextMoveToPoint(ctx, 0, size.height);
		CGContextAddLineToPoint(ctx, size.width, self.frame.size.height);
	}
	
	CGContextSetStrokeColorWithColor(ctx, self.color.CGColor);
	CGContextSetLineWidth(ctx, WLConstants.pixelSize * 2.0f);
	CGContextStrokePath(ctx);
}

@end
