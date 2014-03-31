//
//  VerticalStreamLayout.m
//  StreamView
//
//  Created by Sergey Maximenko on 27.11.13.
//  Copyright (c) 2013 Mobidev. All rights reserved.
//

#import "VerticalStreamLayout.h"

@interface VerticalStreamLayout ()

@end

@implementation VerticalStreamLayout

- (void)prepareLayout {
	[super prepareLayout];
	_initialRange = CGRectGetMaxY(self.streamView.headerView.frame);
	_innerSize = (self.streamView.frame.size.width - self.spacing);
	_size = _innerSize / _numberOfColumns;
	[self setRange:_initialRange];
}

- (CGRect)frameForItemWithRatio:(CGFloat)ratio {
	NSInteger column = 0;
	CGFloat range = [self minimumRange:&column];
	CGFloat scaledWidth = _size;
	CGFloat scaledHeight = _size / ratio;
	CGFloat spacingXScale = (scaledWidth - _spacing) / scaledWidth;
	CGFloat spacingYScale = (scaledHeight - _spacing) / scaledHeight;
	CGRect frame = CGRectMake(_size * column + _spacing / 2.0f, range + ((range == _initialRange) ? _spacing / 2.0f : 0.0f), scaledWidth, scaledHeight);
	ranges[column] = CGRectGetMaxY(frame);
	return CGRectScale(frame, spacingXScale, spacingYScale);
}

- (CGRect)frameForSupplementaryViewWithRatio:(CGFloat)ratio {
	CGFloat range = [self maximumRange:NULL];
	CGFloat scaledWidth = _innerSize;
	CGFloat scaledHeight = _innerSize / ratio;
	CGFloat spacingXScale = (scaledWidth - _spacing) / scaledWidth;
	CGFloat spacingYScale = (scaledHeight - _spacing) / scaledHeight;
	CGRect frame = CGRectMake(_spacing / 2.0f, range + ((range == _initialRange) ? _spacing / 2.0f : 0.0f), scaledWidth, scaledHeight);
	[self updateRange:CGRectGetMaxY(frame)];
	return CGRectScale(frame, spacingXScale, spacingYScale);
}

- (CGSize)contentSize {
	return CGSizeMake(self.streamView.frame.size.width, [self maximumRange:NULL]);
}

- (BOOL)shouldLoadData {
	StreamView* streamView = self.streamView;
	CGFloat contentHeight = streamView.contentSize.height;
	if (contentHeight > 0 && streamView.contentOffset.y >= (contentHeight - streamView.bounds.size.height)) {
		return YES;
	}
	return NO;
}

- (BOOL)shouldRefreshData {
	StreamView* streamView = self.streamView;
	return streamView.contentOffset.y <= -88;
}

- (void)beginRefreshingAnimated:(BOOL)animated {
	StreamView* streamView = self.streamView;
	UIEdgeInsets insets = UIEdgeInsetsZero;
	insets.top = 88;
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
	insets.top = 0.0f;
	insets.bottom = stop ? 0.0f : 88;
	if (animated) {
		[UIView beginAnimations:nil context:nil];
	}
	streamView.contentInset = insets;
	if (animated) {
		[UIView commitAnimations];
	}
}

@end
