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
	_size = ceilf(self.streamView.frame.size.width / _numberOfColumns);
	[self setRange:0];
}

- (CGRect)frameForItemWithRatio:(CGFloat)ratio {
	NSInteger column = 0;
	CGFloat range = [self minimumRange:&column];
	CGFloat scaledWidth = _size;
	CGFloat scaledHeight = _size / ratio;
	CGRect frame = CGRectMake(_size * column, range, scaledWidth, scaledHeight);
	ranges[column] = CGRectGetMaxY(frame);
	return CGRectIntegral(frame);
}

- (CGSize)contentSize {
	return CGSizeMake(self.streamView.frame.size.width, [self maximumRange:NULL]);
}

@end
