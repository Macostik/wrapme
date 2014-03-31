//
//  PICStreamLayout.m
//  RIOT
//
//  Created by Sergey Maximenko on 09.10.13.
//  Copyright (c) 2013 Mobidev. All rights reserved.
//

#import "StreamLayout.h"

@interface StreamLayout ()



@end

@implementation StreamLayout

- (void)dealloc {
    if (ranges != NULL) {
        free(ranges);
    }
}

- (void)prepareLayout {
}

- (void)setRange:(CGFloat)range {
	if (ranges != NULL) {
		free(ranges);
	}
	ranges = calloc(_numberOfColumns, sizeof(CGFloat));
	[self updateRange:range];
}

- (void)setRange:(CGFloat)range atIndex:(NSInteger)index {
	ranges[index] = range;
}

- (void)updateRange:(CGFloat)range {
	for (int i = 0; i < _numberOfColumns; i++) {
		[self setRange:range atIndex:i];
	}
}

- (CGFloat)minimumRange:(NSInteger *)column {
	CGFloat range = CGFLOAT_MAX;
	for (int i = 0; i < _numberOfColumns; i++) {
		CGFloat r = ranges[i];
		if (r < range) {
			if (column != NULL) {
				*column = i;
			}
			range = r;
		}
	}
	return range;
}

- (CGFloat)maximumRange:(NSInteger *)column {
	CGFloat range = 0;
	for (int i = 0; i < _numberOfColumns; i++) {
		CGFloat r = ranges[i];
		if (r > range) {
			if (column != NULL) {
				*column = i;
			}
			range = r;
		}
	}
	return range;
}

- (NSSet*)layoutItems:(NSUInteger)numberOfItems
						 ratio:(CGFloat (^)(StreamLayoutItem *item, NSUInteger itemIndex))ratio {
	NSMutableSet* items = [NSMutableSet set];
	
	for (NSInteger itemIndex = 0; itemIndex < numberOfItems; ++itemIndex) {
		StreamLayoutItem *item = [[StreamLayoutItem alloc] init];
		item.frame = [self frameForItemWithRatio:ratio(item, itemIndex)];
		[items addObject:item];
	}
	
	[self setRange:[self maximumRange:NULL]];
	
	return [items copy];
}

- (StreamLayoutItem *)layoutSupplementaryItem:(CGFloat)ratio {
	StreamLayoutItem *item = [[StreamLayoutItem alloc] init];
	item.frame = [self frameForSupplementaryViewWithRatio:ratio];
	return item;
}

- (CGRect)frameForItemWithRatio:(CGFloat)ratio {
	return CGRectZero;
}

- (CGRect)frameForSupplementaryViewWithRatio:(CGFloat)ratio {
	return CGRectZero;
}

- (BOOL)shouldLoadData {
	return NO;
}

- (BOOL)shouldRefreshData {
	return NO;
}

- (void)beginRefreshingAnimated:(BOOL)animated {
}

- (void)reloadInsets:(BOOL)stop animated:(BOOL)animated {
}

@end

CGRect CGRectScale(CGRect rect, CGFloat xScale, CGFloat yScale) {
	CGFloat width = rect.size.width * xScale;
	CGFloat height = rect.size.height * yScale;
	return CGRectMake(rect.origin.x - (width - rect.size.width) / 2.0f, rect.origin.y - (height - rect.size.height) / 2.0f, width, height);
}
