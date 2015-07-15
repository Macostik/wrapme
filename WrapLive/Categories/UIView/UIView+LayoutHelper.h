//
//  UIView+LayoutHelper.h
//  wrapLive
//
//  Created by Sergey Maximenko on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (LayoutHelper)

@property (nonatomic) BOOL horizontallyResistible;

@property (nonatomic) BOOL verticallyResistible;

@property (nonatomic) BOOL horizontallyHuggable;

@property (nonatomic) BOOL verticallyHuggable;

@property (nonatomic) CGFloat horizontalContentCompressionResistancePriority;

@property (nonatomic) CGFloat verticalContentCompressionResistancePriority;

@property (nonatomic) CGFloat horizontalContentHuggingPriority;

@property (nonatomic) CGFloat verticalContentHuggingPriority;

- (void)makeResizibleSubview:(UIView *)view;

- (NSLayoutConstraint *)constraintToItem:(id)item equal:(NSLayoutAttribute)attribute;

- (NSLayoutConstraint *)constraintForAttrbute:(NSLayoutAttribute)attribute1 toItem:(id)item equalToAttribute:(NSLayoutAttribute)attribute2;

@end
