//
//  WLGradientView.h
//  meWrap
//
//  Created by Ravenpod on 1/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLGradientView : UIView

@property (strong, nonatomic) IBInspectable UIColor* startColor;

@property (strong, nonatomic) IBInspectable UIColor* endColor;

@property (assign, nonatomic) IBInspectable CGFloat startLocation;

@property (assign, nonatomic) IBInspectable CGFloat endLocation;

@end
