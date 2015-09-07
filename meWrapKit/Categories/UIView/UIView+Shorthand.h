//
//  UIView+Shorthand.h
//
//  Created by Andrey Ivanov on 23.10.12.
//  Copyright (c) 2012 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Shorthand)

@property (nonatomic) CGPoint origin;
@property (nonatomic) CGSize size;
@property (nonatomic, readonly) CGSize retinaSize;

@property (nonatomic) CGFloat centerX;
@property (nonatomic) CGFloat centerY;

@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;

@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;

@property (nonatomic) CGFloat right;
@property (nonatomic) CGFloat bottom;

@property (nonatomic) CGPoint leftTop;
@property (nonatomic) CGPoint leftBottom;
@property (nonatomic) CGPoint rightTop;
@property (nonatomic) CGPoint rightBottom;

@property (nonatomic, readonly) CGPoint leftTopBoundary;
@property (nonatomic, readonly) CGPoint leftBottomBoundary;
@property (nonatomic, readonly) CGPoint rightTopBoundary;
@property (nonatomic, readonly) CGPoint rightBottomBoundary;
@property (nonatomic, readonly) CGPoint centerBoundary;

- (void)setY:(CGFloat)y height:(CGFloat)height;

- (void)setX:(CGFloat)x width:(CGFloat)width;

- (void)setFullFlexible;

- (void)setFlexibleBottom;

- (void)setVerticallyFlexible;

@end
