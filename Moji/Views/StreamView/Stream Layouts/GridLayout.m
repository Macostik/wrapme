//
//  GridLayout.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "GridLayout.h"
#import "GridMetrics.h"

@interface GridLayout ()

@property (nonatomic) CGFloat* ranges;

@property (nonatomic) CGFloat* sizes;

@end

@implementation GridLayout

- (void)dealloc {
    self.ranges = NULL;
    self.sizes = NULL;
}

- (void)setSizes:(CGFloat *)sizes {
    if (_sizes != NULL) {
        free(_sizes);
        _sizes = NULL;
    }
    _sizes = sizes;
}

- (void)setRanges:(CGFloat *)ranges {
    if (_ranges != NULL) {
        free(_ranges);
        _ranges = NULL;
    }
    _ranges = ranges;
}

- (CGFloat)offset:(NSInteger)column {
    CGFloat offset = 0;
    for (NSInteger index = 1; index <= column; ++index) {
        offset += self.sizes[index-1];
    }
    return offset;
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

- (void)prepare {
    NSUInteger numberOfColumns = 1;
    id <GridLayoutDelegate> delegate = (id)self.streamView.delegate;
    if ([delegate respondsToSelector:@selector(streamView:layoutNumberOfColumns:)]) {
        numberOfColumns = [delegate streamView:self.streamView layoutNumberOfColumns:self];
    }
    self.numberOfColumns = numberOfColumns;
    self.sizes = calloc(numberOfColumns, sizeof(CGFloat));
    self.ranges = calloc(numberOfColumns, sizeof(CGFloat));
    
    for (NSInteger column = 0; column < numberOfColumns; ++column) {
        
        CGFloat size = ceilf(self.streamView.frame.size.width / numberOfColumns);
        if ([delegate respondsToSelector:@selector(streamView:layout:sizeForColumn:)]) {
            size = [delegate streamView:self.streamView layout:self sizeForColumn:column];
        }
        self.sizes[column] = size;
        
        CGFloat range = 0;
        if ([delegate respondsToSelector:@selector(streamView:layout:rangeForColumn:)]) {
            range = [delegate streamView:self.streamView layout:self rangeForColumn:column];
        }
        self.ranges[column] = range;
    }
}

- (StreamItem *)layout:(StreamItem *)item {
    NSInteger column = 0;
    CGFloat range = [self minimumRange:&column];
    CGFloat size = self.sizes[column];
    CGFloat ratio = [[(GridMetrics*)item.metrics ratio] valueAt:item.index];
    CGRect frame = CGRectMake([self offset:column], range, size, size / ratio);
    self.ranges[column] = CGRectGetMaxY(frame);
    item.frame = frame;
    return item;
}

- (void)flatten {
    CGFloat range = [self maximumRange:NULL];
    for (NSInteger column = 0; column < _numberOfColumns; ++column) {
        self.ranges[column] = range;
    }
}

- (void)prepareForNextSection {
    [self flatten];
}

- (CGSize)contentSize {
    return CGSizeMake(self.streamView.frame.size.width, [self maximumRange:NULL]);
}

@end
