//
//  UIScrollView+Additions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (Additions)

@property (nonatomic, readonly) CGPoint maximumContentOffset;

@property (readonly, nonatomic) BOOL scrollable;

@property (readonly, nonatomic) CGFloat verticalContentInsets;

@property (readonly, nonatomic) CGFloat horizontalContentInsets;

- (void)scrollToTopAnimated:(BOOL)animated;

- (void)scrollToBottomAnimated:(BOOL)animated;

- (BOOL)isPossibleContentOffset:(CGPoint)contentOffset;

- (void)trySetContentOffset:(CGPoint)contentOffset;

- (void)trySetContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

@end
