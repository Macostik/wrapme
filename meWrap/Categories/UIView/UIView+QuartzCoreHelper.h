//
//  UIView+QuartzCoreHelper.h
//  Wrap
//
//  Created by Sergey Maximenko on 8/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (QuartzCoreHelper)

@property (strong, nonatomic) IBInspectable UIColor  *borderColor;

@property (nonatomic) IBInspectable CGFloat cornerRadius;

@property (nonatomic) IBInspectable CGFloat borderWidth;

@property (nonatomic) IBInspectable BOOL circled;

@end
