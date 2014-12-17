//
//  WLButton.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/22/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIFont+CustomFonts.h"

@interface WLButton : UIButton <WLFontCustomizing>

@property (strong, nonatomic) UIColor *normalColor;

@property (strong, nonatomic) UIColor *highlightedColor;

@property (strong, nonatomic) UIColor *selectedColor;

@property (strong, nonatomic) UIColor *disabledColor;

@property (weak, nonatomic) IBOutlet UIView* accessoryView;

@property (strong, nonatomic) UIColor *spinnerColor;

@property (nonatomic) BOOL loading;

@property (nonatomic) BOOL animated;

- (UIColor *)defaultNormalColor;

- (UIColor *)defaultHighlightedColor;

- (UIColor *)defaultSelectedColor;

- (UIColor *)defaultDisabledColor;

@end

@interface WLSegmentButton : WLButton @end

@interface WLPressButton : WLButton @end