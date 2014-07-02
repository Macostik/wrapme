//
//  UIScrollView+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIScrollView+Additions.h"
#import "WLSupportFunctions.h"

@implementation UIScrollView (Additions)

- (void)scrollToTopAnimated:(BOOL)animated {
	[self setContentOffset:CGPointZero animated:animated];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
	if (self.contentSize.height > self.bounds.size.height) {
		[self setContentOffset:CGPointMake(0, self.maximumContentOffset.y) animated:animated];
	}
}

- (void)trySetContentOffset:(CGPoint)contentOffset {
    CGPoint maximumContentOffset = self.maximumContentOffset;
    if (IsInBounds(0, maximumContentOffset.x, contentOffset.x) && IsInBounds(0, maximumContentOffset.y, contentOffset.y)) {
        self.contentOffset = contentOffset;
    }
}

- (CGPoint)maximumContentOffset {
    CGSize contentSize = self.contentSize;
    CGSize size = self.bounds.size;
    return CGPointMake(contentSize.width - size.width, contentSize.height - size.height);
}

@end
