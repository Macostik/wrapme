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

- (CGFloat)fitWidth {
	return [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, self.height)].width;
}

- (void)sizeToFitHeightWithMaximumHeightToSuperviewBottom {
	[self sizeToFitHeightWithMaximumHeight:self.superview.height - self.y];
}

- (void)sizeToFitHeightWithMaximumHeight:(CGFloat)maximumHeight {
	self.height = (maximumHeight > 0) ? MIN(maximumHeight, self.fitHeight) : self.fitHeight;
}

- (void)sizeToFitHeight {
	[self sizeToFitHeightWithMaximumHeight:0];
}

- (void)sizeToFitWidthWithMaximumHeightToSuperviewRight {
	[self sizeToFitWidthWithSuperviewRightPadding:0];
}

- (void)sizeToFitWidthWithSuperviewRightPadding:(CGFloat)padding {
	[self sizeToFitWidthWithMaximumWidth:self.superview.width - self.x - padding];
}

- (void)sizeToFitWidthWithMaximumWidth:(CGFloat)maximumWidth {
	self.width = (maximumWidth > 0) ? MIN(maximumWidth, self.fitWidth) : self.fitWidth;
}

- (void)sizeToFitWidth {
	[self sizeToFitWidthWithMaximumWidth:0];
}

@end
