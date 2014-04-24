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
	[self setContentOffset:CGPointZero animated:animated];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
	[self setContentOffset:CGPointMake(0, self.contentSize.height - self.bounds.size.height) animated:animated];
}

@end
