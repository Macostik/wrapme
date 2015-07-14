//
//  UIView+Extentions.h
//
//  Created by Yuriy Granchenko on 28.05.14.
//  Copyright (c) 2014 Roman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Extentions)

@property (nonatomic, readwrite, strong) UIView *parentView;

@property (nonatomic) BOOL highHorizontalContentCompressionResistance;

@property (nonatomic) BOOL highVerticalContentCompressionResistance;

@property (nonatomic) BOOL lowHorizontalContentCompressionResistance;

@property (nonatomic) BOOL lowVerticalContentCompressionResistance;

@property (nonatomic) BOOL highHorizontalContentHugging;

@property (nonatomic) BOOL highVerticalContentHugging;

@property (nonatomic) BOOL lowHorizontalContentHugging;

@property (nonatomic) BOOL lowVerticalContentHugging;

- (void)logSubviewsHierarchy;

- (void)makeResizibleSubview:(UIView *)view;

- (id)findFirstResponder;

- (NSLayoutConstraint *)constraintToItem:(id)item equal:(NSLayoutAttribute)attribute;

- (NSLayoutConstraint *)constraintForAttrbute:(NSLayoutAttribute)attribute1 toItem:(id)item equalToAttribute:(NSLayoutAttribute)attribute2;

- (void)setHorizontalContentCompressionResistancePriority:(CGFloat)priority;

- (void)setVerticalContentCompressionResistancePriority:(CGFloat)priority;

- (void)setHorizontalContentHuggingPriority:(CGFloat)priority;

- (void)setVerticalContentHuggingPriority:(CGFloat)priority;

@end
