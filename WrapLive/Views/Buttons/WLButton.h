//
//  WLButton.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/22/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLButton : UIButton

@property (strong, nonatomic) UIColor *normalColor;

@property (strong, nonatomic) UIColor *highlightedColor;

@property (strong, nonatomic) UIColor *selectedColor;

@property (strong, nonatomic) UIColor *disabledColor;

@end

@interface WLSegmentButton : WLButton @end
