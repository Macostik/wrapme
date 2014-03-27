//
//  PGSeparatorView.m
//  Pressgram
//
//  Created by Sergey Maximenko on 30.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import "WLSeparatorView.h"

@interface WLSeparatorView ()

@end

@implementation WLSeparatorView

- (void)awakeFromNib {
	[super awakeFromNib];
	
	self.fillColor = self.backgroundColor;
	[super setBackgroundColor:[UIColor clearColor]];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if (self.contentMode == UIViewContentModeTop) {
		CGContextMoveToPoint(ctx, 0, 0);
		CGContextAddLineToPoint(ctx, self.frame.size.width, 0);
	} else {
		if (self.frame.size.height > self.frame.size.width) {
			CGContextMoveToPoint(ctx, self.frame.size.width, 0);
		} else {
			CGContextMoveToPoint(ctx, 0, self.frame.size.height);
		}
		CGContextAddLineToPoint(ctx, self.frame.size.width, self.frame.size.height);
	}
	
	CGContextSetStrokeColorWithColor(ctx, self.fillColor.CGColor);
	CGContextSetLineWidth(ctx, 1);
	CGContextStrokePath(ctx);
}

@end
