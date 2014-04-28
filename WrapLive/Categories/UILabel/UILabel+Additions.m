//
//  UILabel+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UILabel+Additions.h"
#import "UIView+Shorthand.h"

@implementation UILabel (Additions)

- (CGFloat)fitHeight {
	return [self sizeThatFits:CGSizeMake(self.width, CGFLOAT_MAX)].height;
}

- (void)sizeToFitHeightWithMaximumHeightToSuperviewBottom {
	[self sizeToFitHeightWithMaximumHeight:self.superview.height - self.y];
}

- (void)sizeToFitHeightWithMaximumHeight:(CGFloat)minimumHeight {
	CGFloat height = self.fitHeight;
	if (minimumHeight > 0) {
		height = MIN(minimumHeight, height);
	}
	self.height = height;
}

- (void)sizeToFitHeight {
	[self sizeToFitHeightWithMaximumHeight:0];
}

@end
