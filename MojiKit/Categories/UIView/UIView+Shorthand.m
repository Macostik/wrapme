//
//  UIView+Shorthand.m
//
//  Created by Andrey Ivanov on 23.10.12.
//  Copyright (c) 2012 Ravenpod. All rights reserved.
//

#import "UIView+Shorthand.h"

@implementation UIView (Shorthand)

- (CGPoint)origin {
	return self.frame.origin;
}

- (void)setOrigin:(CGPoint)newOrigin {
	CGRect frame = self.frame;
	frame.origin = newOrigin;
	self.frame = frame;
}

- (CGFloat)centerX {
	return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
	self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY {
	return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
	self.center = CGPointMake(self.center.x, centerY);
}

- (CGFloat)x {
	return self.frame.origin.x;
}

- (void)setX:(CGFloat)x {
	CGRect frame = self.frame;
	frame.origin.x = x;
	self.frame = frame;
}

- (CGFloat)y {
	return self.frame.origin.y;
}

- (void)setY:(CGFloat)y {
	CGRect frame = self.frame;
	frame.origin.y = y;
	self.frame = frame;
}

- (CGFloat)width {
	return self.bounds.size.width;
}

- (void)setWidth:(CGFloat)newWidth {
	CGRect frame = self.frame;
	frame.size.width = newWidth;
	self.frame = frame;
}

- (CGFloat)height {
	return self.bounds.size.height;
}

- (void)setHeight:(CGFloat)newHeight {
	CGRect frame = self.frame;
	frame.size.height = newHeight;
	self.frame = frame;
}

- (CGSize)size {
	return self.bounds.size;
}

- (void)setSize:(CGSize)newSize {
	CGRect frame = self.frame;
	frame.size = newSize;
	self.frame = frame;
}

- (CGSize)retinaSize {
	return CGRetinaSize(self.size);
}

- (CGFloat)right {
    return CGRectGetMaxX(self.frame);
}

- (void)setRight:(CGFloat)right {
	CGRect frame = self.frame;
	frame.origin.x = right - frame.size.width;
	self.frame = frame;
}

- (CGFloat)bottom {
    return CGRectGetMaxY(self.frame);
}

- (void)setBottom:(CGFloat)bottom {
	CGRect frame = self.frame;
	frame.origin.y = bottom - frame.size.height;
	self.frame = frame;
}

- (void)setY:(CGFloat)y height:(CGFloat)height {
    CGRect frame = self.frame;
    frame.origin.y = y;
    frame.size.height = height;
    self.frame = frame;
}

- (void)setX:(CGFloat)x width:(CGFloat)width {
    CGRect frame = self.frame;
    frame.origin.x = x;
    frame.size.width = width;
    self.frame = frame;
}

// corner points

- (CGPoint)leftTop {
	return self.origin;
}

- (void)setLeftTop:(CGPoint)leftTop {
	self.origin = leftTop;
}

- (CGPoint)leftBottom {
	return CGPointMake(CGRectGetMinX(self.frame), CGRectGetMaxY(self.frame));
}

- (void)setLeftBottom:(CGPoint)leftBottom {
	self.origin = CGPointMake(leftBottom.x, leftBottom.y - CGRectGetHeight(self.frame));
}

- (CGPoint)rightTop {
	return CGPointMake(CGRectGetMaxX(self.frame), CGRectGetMinY(self.frame));
}

- (void)setRightTop:(CGPoint)rightTop {
	self.origin = CGPointMake(rightTop.x - CGRectGetWidth(self.frame), rightTop.y);
}

- (CGPoint)rightBottom {
	return CGPointMake(CGRectGetMaxX(self.frame), CGRectGetMaxY(self.frame));
}

- (void)setRightBottom:(CGPoint)rightBottom {
	self.origin = CGPointMake(rightBottom.x - CGRectGetWidth(self.frame), rightBottom.y - CGRectGetHeight(self.frame));
}

// boundary corner points

- (CGPoint)leftTopBoundary {
	return self.bounds.origin;
}

- (CGPoint)leftBottomBoundary {
	return CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds));
}

- (CGPoint)rightTopBoundary {
	return CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMinY(self.bounds));
}

- (CGPoint)rightBottomBoundary {
	return CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds));
}

- (CGPoint)centerBoundary {
	return CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)setFullFlexible {
	self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
}

- (void)setFlexibleBottom {
	self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
}

- (void)setVerticallyFlexible {
    self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
}

@end
