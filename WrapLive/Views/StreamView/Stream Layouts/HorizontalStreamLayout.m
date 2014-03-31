//
//  HorizontalStreamLayout.m
//  StreamView
//
//  Created by Sergey Maximenko on 27.11.13.
//  Copyright (c) 2013 Mobidev. All rights reserved.
//

#import "HorizontalStreamLayout.h"

@interface HorizontalStreamLayout ()

@end

@implementation HorizontalStreamLayout

- (void)prepareLayout {
	[super prepareLayout];
	_initialRange = CGRectGetMaxX(self.streamView.headerView.frame);
	_innerSize = (self.streamView.frame.size.height - self.spacing);
	_size = _innerSize / _numberOfColumns;
	[self setRange:_initialRange];
}

- (CGRect)frameForItemWithRatio:(CGFloat)ratio {
	NSInteger column = 0;
	CGFloat range = [self minimumRange:&column];
	CGFloat scaledWidth = _size * ratio;
	CGFloat scaledHeight = _size;
	CGFloat spacingYScale = (scaledHeight - _spacing) / scaledHeight;
	CGFloat spacingXScale = (scaledWidth - _spacing) / scaledWidth;
	CGRect frame = CGRectMake(range + ((range == _initialRange) ? _spacing / 2.0f : 0.0f), _size * column + _spacing / 2.0f, scaledWidth, scaledHeight);
	self->ranges[column] = CGRectGetMaxX(frame);
	return CGRectScale(frame, spacingXScale, spacingYScale);
}

- (CGRect)frameForSupplementaryViewWithRatio:(CGFloat)ratio {
	CGFloat range = [self maximumRange:NULL];
	CGFloat scaledWidth = _innerSize * ratio;
	CGFloat scaledHeight = _innerSize;
	CGFloat spacingYScale = (scaledHeight - _spacing) / scaledHeight;
	CGFloat spacingXScale = (scaledWidth - _spacing) / scaledWidth;
	CGRect frame = CGRectMake(range + ((range == _initialRange) ? _spacing / 2.0f : 0.0f), _spacing / 2.0f, scaledWidth, scaledHeight);
	[self updateRange:CGRectGetMaxX(frame)];
	return CGRectScale(frame, spacingXScale, spacingYScale);
}

- (CGSize)contentSize {
	return CGSizeMake([self maximumRange:NULL], self.streamView.frame.size.height);
}

- (BOOL)shouldLoadData {
	StreamView* streamView = self.streamView;
	CGFloat contentWidth = streamView.contentSize.width;
	if (contentWidth > 0 && streamView.contentOffset.x >= (contentWidth - streamView.bounds.size.width)) {
		return YES;
	}
	return NO;
}

- (BOOL)shouldRefreshData {
	StreamView* streamView = self.streamView;
	return streamView.contentOffset.x <= -88;
}

- (void)beginRefreshingAnimated:(BOOL)animated {
	StreamView* streamView = self.streamView;
	UIEdgeInsets insets = UIEdgeInsetsZero;
	insets.left = 88;
	if (animated) {
		[UIView beginAnimations:nil context:nil];
	}
	streamView.contentInset = insets;
	if (animated) {
		[UIView commitAnimations];
	}
}

- (void)reloadInsets:(BOOL)stop animated:(BOOL)animated {
	StreamView* streamView = self.streamView;
	UIEdgeInsets insets = UIEdgeInsetsZero;
	insets.left = 0.0f;
	insets.right = stop ? 0.0f : 88;
	if (animated) {
		[UIView beginAnimations:nil context:nil];
	}
	streamView.contentInset = insets;
	if (animated) {
		[UIView commitAnimations];
	}
}

@end
