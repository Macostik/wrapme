//
//  PICStreamLayout.m
//  RIOT
//
//  Created by Ravenpod on 09.10.13.
//  Copyright (c) 2013 Ravenpod. All rights reserved.
//

#import "StreamLayout.h"

@interface StreamLayout ()



@end

@implementation StreamLayout

- (void)dealloc {
	self.ranges = NULL;
	self.sizes = NULL;
}

- (void)setRanges:(CGFloat *)ranges {
	if (_ranges != NULL) {
		free(_ranges);
		_ranges = NULL;
	}
	_ranges = ranges;
}

- (void)setNumberOfColumns:(NSInteger)numberOfColumns {
	_numberOfColumns = numberOfColumns;
	self.sizes = calloc(_numberOfColumns, sizeof(CGFloat));
	self.ranges = calloc(_numberOfColumns, sizeof(CGFloat));
	[self setRange:0];
}

- (void)setSize:(CGFloat)size {
	for (NSInteger index = 0; index < _numberOfColumns; ++index) {
        [self setSize:size atIndex:index];
    }
}

- (void)setSize:(CGFloat)size atIndex:(NSInteger)index {
	if (index < _numberOfColumns) {
		self.sizes[index] = size;
	}
}

- (CGFloat)offset:(NSInteger)column {
	CGFloat offset = 0;
	for (NSInteger index = 1; index <= column; ++index) {
        offset += self.sizes[index-1];
    }
	return offset;
}

- (void)setRange:(CGFloat)range {
	
	[self updateRange:range];
}

- (void)setRange:(CGFloat)range atIndex:(NSInteger)index {
	self.ranges[index] = range;
}

- (void)updateRange:(CGFloat)range {
	for (int i = 0; i < _numberOfColumns; i++) {
		[self setRange:range atIndex:i];
	}
}

- (CGFloat)minimumRange:(NSInteger *)column {
	CGFloat range = CGFLOAT_MAX;
	for (int i = 0; i < _numberOfColumns; i++) {
		CGFloat r = self.ranges[i];
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
		CGFloat r = self.ranges[i];
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

- (CGRect)frameForItemWithRatio:(CGFloat)ratio {
	return CGRectZero;
}

@end

CGRect CGRectScale(CGRect rect, CGFloat xScale, CGFloat yScale) {
	CGFloat width = rect.size.width * xScale;
	CGFloat height = rect.size.height * yScale;
	return CGRectMake(rect.origin.x - (width - rect.size.width) / 2.0f, rect.origin.y - (height - rect.size.height) / 2.0f, width, height);
}
