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

@property (nonatomic) CGFloat* offsets;

@property (nonatomic) CGFloat* sizes;

@property (nonatomic) CGFloat spacing;

@end

@implementation GridLayout

- (void)dealloc {
    self.offsets = NULL;
    self.sizes = NULL;
}

- (void)setSizes:(CGFloat *)sizes {
    if (_sizes != NULL) {
        free(_sizes);
        _sizes = NULL;
    }
    _sizes = sizes;
}

- (void)setOffsets:(CGFloat *)offsets {
    if (_offsets != NULL) {
        free(_offsets);
        _offsets = NULL;
    }
    _offsets = offsets;
}

- (CGFloat)position:(NSInteger)column {
    CGFloat position = 0;
    for (NSInteger index = 1; index <= column; ++index) {
        position += self.sizes[index-1];
    }
    return position * (self.horizontal ? self.streamView.height : self.streamView.width);
}

- (CGFloat)minimumOffset:(NSInteger *)column {
    CGFloat offset = CGFLOAT_MAX;
    for (int i = 0; i < _numberOfColumns; i++) {
        CGFloat r = self.offsets[i];
        if (r < offset) {
            if (column != NULL) {
                *column = i;
            }
            offset = r;
        }
    }
    return offset;
}

- (CGFloat)maximumOffset:(NSInteger *)column {
    CGFloat offset = 0;
    for (int i = 0; i < _numberOfColumns; i++) {
        CGFloat r = self.offsets[i];
        if (r > offset) {
            if (column != NULL) {
                *column = i;
            }
            offset = r;
        }
    }
    return offset;
}

- (void)prepare {
    NSUInteger numberOfColumns = 1;
    id <GridLayoutDelegate> delegate = (id)self.streamView.delegate;
    if ([delegate respondsToSelector:@selector(streamView:layoutNumberOfColumns:)]) {
        numberOfColumns = [delegate streamView:self.streamView layoutNumberOfColumns:self];
    }
    self.numberOfColumns = numberOfColumns;
    self.sizes = calloc(numberOfColumns, sizeof(CGFloat));
    self.offsets = calloc(numberOfColumns, sizeof(CGFloat));
    
    for (NSInteger column = 0; column < numberOfColumns; ++column) {
        
        CGFloat size = (self.streamView.frame.size.width / numberOfColumns) / self.streamView.frame.size.width;
        if ([delegate respondsToSelector:@selector(streamView:layout:sizeForColumn:)]) {
            size = [delegate streamView:self.streamView layout:self sizeForColumn:column];
        }
        self.sizes[column] = size;
        
        CGFloat offset = 0;
        if ([delegate respondsToSelector:@selector(streamView:layout:offsetForColumn:)]) {
            offset = [delegate streamView:self.streamView layout:self offsetForColumn:column];
        }
        self.offsets[column] = offset;
    }
    
    if ([delegate respondsToSelector:@selector(streamView:layoutSpacing:)]) {
        self.spacing = [delegate streamView:self.streamView layoutSpacing:self];
    }
}

- (StreamItem *)layout:(StreamItem *)item {
    
    StreamView *streamView = self.streamView;
    GridMetrics *metrics = (GridMetrics*)item.metrics;
    
    CGFloat ratio = 1;
    if ([metrics isKindOfClass:[GridMetrics class]]) {
        ratio = [metrics ratioAt:item.index];
    } else {
        ratio = (self.horizontal ? streamView.height : streamView.width) / [metrics sizeAt:item.index];
    }
    
    NSInteger column = 0;
    CGFloat offset = [self minimumOffset:&column];
    CGFloat size = self.sizes[column] * (self.horizontal ? streamView.height : streamView.width);
    
    CGFloat spacing = self.spacing;
    CGFloat spacing_2 = spacing/2.0f;
    CGRect frame = CGRectZero;
    if (self.horizontal) {
        frame = CGRectMake(offset, [self position:column], size / ratio, size);
        if (column == 0) {
            frame.origin.y += spacing;
            frame.size.height -= spacing + spacing_2;
            frame.size.width -= spacing;
        } else if (column == _numberOfColumns - 1) {
            frame.origin.y += spacing_2;
            frame.size.height -= spacing + spacing_2;
            frame.size.width -= spacing;
        } else {
            frame.origin.y += spacing_2;
            frame.size.height -= spacing;
            frame.size.width -= spacing;
        }
        self.offsets[column] = CGRectGetMaxX(frame) + spacing;
    } else {
        frame = CGRectMake([self position:column], offset, size, size / ratio);
        if (column == 0) {
            frame.origin.x += spacing;
            frame.size.width -= spacing + spacing_2;
            frame.size.height -= spacing;
        } else if (column == _numberOfColumns - 1) {
            frame.origin.x += spacing_2;
            frame.size.width -= spacing + spacing_2;
            frame.size.height -= spacing;
        } else {
            frame.origin.x += spacing_2;
            frame.size.width -= spacing;
            frame.size.height -= spacing;
        }
        self.offsets[column] = CGRectGetMaxY(frame) + spacing;
    }
    
    item.frame = frame;
    return item;
}

- (void)flatten {
    CGFloat offset = [self maximumOffset:NULL];
    for (NSInteger column = 0; column < _numberOfColumns; ++column) {
        self.offsets[column] = offset;
    }
}

- (void)prepareForNextSection {
    [self flatten];
}

- (CGSize)contentSize {
    if (self.horizontal) {
        return CGSizeMake([self maximumOffset:NULL], self.streamView.bounds.size.height);
    } else {
        return CGSizeMake(self.streamView.bounds.size.width, [self maximumOffset:NULL]);
    }
}

@end
