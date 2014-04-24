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

- (void)sizeToFitHeightWithMinimumHeight:(CGFloat)minimumHeight;

- (void)sizeToFitHeight;

@end
