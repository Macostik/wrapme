//
//  WLHintView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 1/19/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

typedef void (^WLHintViewDrawing)(CGContextRef ctx, CGRect rect);

@interface WLHintView : UIView

@property (strong, nonatomic) IBInspectable UIColor* startColor;

@property (strong, nonatomic) IBInspectable UIColor* endColor;

@property (strong, nonatomic) WLHintViewDrawing drawing;

+ (BOOL)showHintViewFromNibNamed:(NSString*)nibName;

+ (BOOL)showHintViewFromNibNamed:(NSString*)nibName drawing:(WLHintViewDrawing)drawing;

+ (BOOL)showHintViewFromNibNamed:(NSString*)nibName inView:(UIView*)view;

+ (BOOL)showHintViewFromNibNamed:(NSString*)nibName inView:(UIView*)view drawing:(WLHintViewDrawing)drawing;

@end

@interface WLHintView (DefinedHintViews)

+ (BOOL)showCandySwipeHintView;

+ (BOOL)showWrapPickerHintViewInView:(UIView *)view withFocusPoint:(CGPoint)focusPoint;

@end
