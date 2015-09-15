//
//  UIScrollView+Additions.m
//  meWrap
//
//  Created by Ravenpod on 24.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "UIScrollView+Additions.h"

@implementation UIScrollView (Additions)

- (void)setMinimumContentOffsetAnimated:(BOOL)animated {
	[self setContentOffset:self.minimumContentOffset animated:animated];
}

- (void)setMaximumContentOffsetAnimated:(BOOL)animated {
    [self setContentOffset:self.maximumContentOffset animated:animated];
}

- (BOOL)isPossibleContentOffset:(CGPoint)contentOffset {
    CGPoint min = self.minimumContentOffset;
    CGPoint max = self.maximumContentOffset;
    return IsInBounds(min.x, max.x, contentOffset.x) && IsInBounds(min.y, max.y, contentOffset.y);
}

- (void)trySetContentOffset:(CGPoint)contentOffset {
    if ([self isPossibleContentOffset:contentOffset]) {
        self.contentOffset = contentOffset;
    }
}

- (void)trySetContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    if ([self isPossibleContentOffset:contentOffset]) {
        [self setContentOffset:contentOffset animated:animated];
    }
}

- (CGPoint)minimumContentOffset {
    UIEdgeInsets insets = self.contentInset;
    return CGPointMake(-insets.left, -insets.top);
}

- (CGPoint)maximumContentOffset {
    CGSize contentSize = self.contentSize;
    CGSize size = self.bounds.size;
    UIEdgeInsets insets = self.contentInset;
    CGFloat width = contentSize.width - (size.width - insets.right);
    CGFloat height = contentSize.height - (size.height - insets.bottom);
    return (CGPoint) {
        .x = (width > -insets.left) ? width : -insets.left,
        .y = (height > -insets.top) ? height : -insets.top
    };
}

- (BOOL)scrollable {
    CGSize contentSize = self.contentSize;
    CGSize fittingContentSize = self.fittingContentSize;
    return (contentSize.width > fittingContentSize.width) || (contentSize.height > fittingContentSize.height);
}

- (CGFloat)verticalContentInsets {
    UIEdgeInsets insets = self.contentInset;
    return insets.top + insets.bottom;
}

- (CGFloat)horizontalContentInsets {
    UIEdgeInsets insets = self.contentInset;
    return insets.left + insets.right;
}

- (CGSize)fittingContentSize {
    return CGSizeMake(self.fittingContentWidth, self.fittingContentHeight);
}

- (CGFloat)fittingContentWidth {
    return self.frame.size.width - self.horizontalContentInsets;
}

- (CGFloat)fittingContentHeight {
    return self.frame.size.height - self.verticalContentInsets;
}

- (CGRect)visibleRectOfRect:(CGRect)rect {
    return [self visibleRectOfRect:rect withContentOffset:self.contentOffset];
}

- (CGRect)visibleRectOfRect:(CGRect)rect withContentOffset:(CGPoint)contentOffset {
    CGRect visibleRect = self.bounds;
    visibleRect.origin = contentOffset;
    return CGRectIntersection(visibleRect, rect);
}

@end
