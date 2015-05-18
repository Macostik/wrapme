//
//  WLButton.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/22/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLButton : UIButton

@property (strong, nonatomic) IBInspectable UIColor *normalColor;

@property (strong, nonatomic) IBInspectable UIColor *highlightedColor;

@property (strong, nonatomic) IBInspectable UIColor *selectedColor;

@property (strong, nonatomic) IBInspectable UIColor *disabledColor;

@property (strong, nonatomic) IBInspectable NSString *preset;

@property (strong, nonatomic) IBInspectable UIColor *spinnerColor;

@property (assign, nonatomic) IBInspectable CGSize insets;

@property (assign, nonatomic) IBInspectable CGSize touchArea;

@property (weak, nonatomic) IBOutlet UIView* accessoryView;

@property (nonatomic) BOOL loading;

@property (nonatomic) BOOL animated;

- (UIColor *)defaultNormalColor;

- (UIColor *)defaultHighlightedColor;

- (UIColor *)defaultSelectedColor;

- (UIColor *)defaultDisabledColor;

@end

@interface WLSegmentButton : WLButton @end

@interface WLPressButton : WLButton @end

@interface UIView (Borders)

@property (strong, nonatomic) IBInspectable UIColor  *borderColor;

@property (nonatomic) IBInspectable CGFloat cornerRadius;

@property (nonatomic) IBInspectable CGFloat borderWidth;

@end
