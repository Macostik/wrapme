//
//  UIView+Extentions.h
//
//  Created by Yuriy Granchenko on 28.05.14.
//  Copyright (c) 2014 Roman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Extentions)

@property (nonatomic, readwrite, strong) UIView *parentView;

- (void)logSubviewsHierarchy;

- (void)makeResizibleSubview:(UIView *)view;

- (id)findFirstResponder;

@end
