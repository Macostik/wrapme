//
//  WLHintView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/19/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLHintView.h"
#import "WLSession.h"
#import "WLNavigation.h"
#import "NSObject+NibAdditions.h"

@implementation WLHintView

+ (BOOL)showHintViewFromNibNamed:(NSString*)nibName {
    return [self showHintViewFromNibNamed:nibName inView:[UIWindow mainWindow].rootViewController.view];
}

+ (BOOL)showHintViewFromNibNamed:(NSString *)nibName inView:(UIView*)view {
    NSMutableDictionary *shownHints = [WLSession object:@"WLHintView_shownHints"];
    if ([shownHints objectForKey:nibName]) return NO;
    
    if (!shownHints) {
        shownHints = [NSMutableDictionary dictionary];
    } else {
        shownHints = [shownHints mutableCopy];
    }
    [shownHints setObject:@YES forKey:nibName];
    [WLSession setObject:shownHints key:@"WLHintView_shownHints"];
    
    UIView * hintView = [UIView loadFromNibNamed:nibName];
    
    hintView.frame = view.frame;
    
    [view addSubview:hintView];
    
    hintView.alpha = 0.0f;
    [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:^{
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

@end
