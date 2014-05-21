//
//  UILabel+Additions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (Additions)

@property (nonatomic, readonly) CGFloat fitHeight;

@property (nonatomic, readonly) CGFloat fitWidth;

- (void)sizeToFitHeightWithMaximumHeightToSuperviewBottom;

- (void)sizeToFitHeightWithMaximumHeight:(CGFloat)minimumHeight;

- (void)sizeToFitHeight;

- (void)sizeToFitWidthWithMaximumHeightToSuperviewRight;

- (void)sizeToFitWidthWithSuperviewRightPadding:(CGFloat)padding;

- (void)sizeToFitWidthWithMaximumWidth:(CGFloat)maximumWidth;

- (void)sizeToFitWidth;

@end
