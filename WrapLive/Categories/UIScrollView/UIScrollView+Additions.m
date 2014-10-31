//
//  UIScrollView+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIScrollView+Additions.h"

@implementation UIScrollView (Additions)

- (void)scrollToTopAnimated:(BOOL)animated {
    UIEdgeInsets insets = self.contentInset;
	[self setContentOffset:CGPointMake(-insets.left, -insets.top) animated:animated];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
//	if (self.contentSize.height > self.bounds.size.height) {
		[self setContentOffset:CGPointMake(0, self.maximumContentOffset.y) animated:animated];
//	}
}

- (BOOL)isPossibleContentOffset:(CGPoint)contentOffset {
    CGPoint maximumContentOffset = self.maximumContentOffset;
    return IsInBounds(0, maximumContentOffset.x, contentOffset.x) && IsInBounds(0, maximumContentOffset.y, contentOffset.y);
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

- (CGPoint)maximumContentOffset {
    CGSize contentSize = self.contentSize;
    CGSize size = self.bounds.size;
    UIEdgeInsets insets = self.contentInset;
    return CGPointMake(contentSize.width - (size.width - insets.right), contentSize.height - (size.height - insets.bottom));
}

- (BOOL)scrollable {
    CGSize size = self.bounds.size;
    CGSize contentSize = self.contentSize;
    UIEdgeInsets insets = self.contentInset;
    if (contentSize.height > (size.height - (insets.bottom + insets.top))) return YES;
    if (contentSize.width > (size.width - (insets.left + insets.right))) return YES;
    return NO;
}

@end
