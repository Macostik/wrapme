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

- (void)setNumberOfColumns:(NSInteger)numberOfColumns {
	[super setNumberOfColumns:numberOfColumns];
	[self setSize:ceilf(self.streamView.frame.size.width / numberOfColumns)];
}

- (CGRect)frameForItemWithRatio:(CGFloat)ratio {
	NSInteger column = 0;
	CGFloat range = [self minimumRange:&column];
	CGFloat size = self.sizes[column];
	CGRect frame = CGRectMake([self offset:column], range, size, size / ratio);
	self.ranges[column] = CGRectGetMaxY(frame);
	return frame;
}

- (CGSize)contentSize {
	return CGSizeMake(self.streamView.frame.size.width, [self maximumRange:NULL]);
}

@end
