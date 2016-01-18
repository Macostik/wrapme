//
//  WLHintView.m
//  meWrap
//
//  Created by Ravenpod on 1/19/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLHintView.h"
#import "WLButton.h"

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
    NSMutableDictionary *shownHints = [NSUserDefaults standardUserDefaults].shownHints;
    
    if ([shownHints objectForKey:nibName]) return NO;
    
    [shownHints setObject:@YES forKey:nibName];
    
    [NSUserDefaults standardUserDefaults].shownHints = shownHints;
    
    WLHintView * hintView = [self loadFromNib:nibName];
    
    hintView.drawing = drawing;
    
    hintView.frame = view.frame;
    
    hintView.gotItButton.layer.borderColor = Color.grayDark.CGColor;
    
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

+ (BOOL)showHomeSwipeTransitionHintViewInView:(UIView *)view {
    return [self showHintViewFromNibNamed:@"WLHomeSwipeTransitionView" inView:view drawing:nil];
}

@end
