//
//  WLHintView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/19/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLHintView.h"
#import "WLNavigationHelper.h"
#import "NSObject+NibAdditions.h"
#import "WLButton.h"
#import "UIFont+CustomFonts.h"

@implementation WLHintView 

+ (BOOL)showHintViewFromNibNamed:(NSString*)nibName {
    return [self showHintViewFromNibNamed:nibName drawing:nil];
}

+ (BOOL)showHintViewFromNibNamed:(NSString*)nibName drawing:(WLHintViewDrawing)drawing {
    return [self showHintViewFromNibNamed:nibName inView:[UIWindow mainWindow].rootViewController.view drawing:drawing];
}

+ (BOOL)showHintViewFromNibNamed:(NSString *)nibName inView:(UIView*)view {
    return [self showHintViewFromNibNamed:nibName inView:view drawing:nil];
}

+ (BOOL)showHintViewFromNibNamed:(NSString *)nibName inView:(UIView*)view drawing:(WLHintViewDrawing)drawing {
    NSMutableDictionary *shownHints = [WLSession object:@"WLHintView_shownHints"];
    if ([shownHints objectForKey:nibName]) return NO;
    
    if (!shownHints) {
        shownHints = [NSMutableDictionary dictionary];
    } else {
        shownHints = [shownHints mutableCopy];
    }
    [shownHints setObject:@YES forKey:nibName];
    [WLSession setObject:shownHints key:@"WLHintView_shownHints"];
    
    WLHintView * hintView = [self loadFromNibNamed:nibName];
    
    hintView.drawing = drawing;
    
    hintView.frame = view.frame;
    
    hintView.gotItButton.layer.borderColor = [UIColor WL_grayDark].CGColor;
    
    [view addSubview:hintView];
    
    [hintView setFullFlexible];
    
    hintView.alpha = 0.0f;
    [UIView animateWithDuration:0.5f delay:0.0f usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        hintView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        
    }];
    
    return YES;
}

- (IBAction)hide {
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        weakSelf.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}

- (UIColor *)startColor {
    if (!_startColor) _startColor = [UIColor blackColor];
    return _startColor;
}

- (UIColor *)endColor {
    if (!_endColor) _endColor = [UIColor colorWithWhite:0 alpha:0.85f];
    return _endColor;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CFArrayRef colors = (__bridge CFArrayRef) @[(id)self.startColor.CGColor, (id)self.endColor.CGColor];
    
    CGGradientRef gradient = CGGradientCreateWithColors(NULL, colors, NULL);
    
    CGContextDrawLinearGradient(ctx, gradient, CGPointMake(0.5, 0.0), CGPointMake(0.5, rect.size.width), kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(gradient);
    
    if (self.drawing) {
        self.drawing(ctx, rect);
    }
}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    [self setNeedsDisplay];
}

@end

@implementation WLHintView (DefinedHintViews)

+ (BOOL)showCandySwipeHintView {
    return [self showHintViewFromNibNamed:@"WLCandySwipeHintView"];
}

+ (BOOL)showWrapPickerHintViewInView:(UIView *)view withFocusPoint:(CGPoint)focusPoint {
    return [self showHintViewFromNibNamed:@"WLWrapPickerHintView" inView:view drawing:^(CGContextRef ctx, CGRect rect) {
        CGFloat size = 196;
        [self toDrawOvalInRect:CGRectMake(focusPoint.x - size/2.0f, focusPoint.y - size/2.0f, size, size)];
    }];
}

+ (BOOL)showInviteHintViewInView:(UIView *)view withFocusToView:(UIView *)target {
    return [self showHintViewFromNibNamed:@"WLInviteHintView" inView:view drawing:^(CGContextRef ctx, CGRect rect) {
        CGFloat size = MAX(target.width, target.height);
        [self toDrawOvalInRect:CGRectMake(target.center.x - size/2.0f, target.center.y + size/2.0f, size, size)];
    }];
}

+ (BOOL)showEditWrapHintViewInView:(UIView *)view withFocusToView:(UIView *)target {
    return [self showHintViewFromNibNamed:@"WLEditWrapHintView" inView:view drawing:^(CGContextRef ctx, CGRect rect) {
        CGFloat size = MAX(target.width, target.height) + 20;
        [self toDrawOvalInRect:CGRectMake(target.center.x - size/2.0f, target.center.y - size/2.0f, size, size)];
    }];
}

+ (void)toDrawOvalInRect:(CGRect)bounds {
    UIBezierPath *transparentPath = [UIBezierPath bezierPathWithOvalInRect:bounds];
    [[UIColor colorWithRed:0.953 green:0.459 blue:0.149 alpha:1.000] setStroke];
    transparentPath.lineWidth = 8;
    [transparentPath stroke];
    [transparentPath fillWithBlendMode:kCGBlendModeClear alpha:1.0f];
}

@end
