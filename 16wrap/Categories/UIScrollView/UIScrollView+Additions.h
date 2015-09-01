//
//  UIScrollView+Additions.h
//  moji
//
//  Created by Ravenpod on 24.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (Additions)

@property (nonatomic, readonly) CGPoint maximumContentOffset;

@property (nonatomic, readonly) CGPoint minimumContentOffset;

@property (readonly, nonatomic) BOOL scrollable;

@property (readonly, nonatomic) CGFloat verticalContentInsets;

@property (readonly, nonatomic) CGFloat horizontalContentInsets;

- (void)setMinimumContentOffsetAnimated:(BOOL)animated;

- (void)setMaximumContentOffsetAnimated:(BOOL)animated;

- (BOOL)isPossibleContentOffset:(CGPoint)contentOffset;

- (void)trySetContentOffset:(CGPoint)contentOffset;

- (void)trySetContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

- (CGRect)visibleRectOfRect:(CGRect)rect;

- (CGRect)visibleRectOfRect:(CGRect)rect withContentOffset:(CGPoint)contentOffset;

@end
