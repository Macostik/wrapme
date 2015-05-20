//
//  WLBaseViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLKeyboard.h"
#import "GAITrackedViewController.h"
#import <WrapLiveKit/WrapLiveKit.h>

@interface WLBaseViewController : GAITrackedViewController <WLKeyboardBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UIView* navigationBar;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *keyboardAdjustmentLayoutViews;

@property (nonatomic) BOOL keyboardAdjustmentAnimated;

@property (nonatomic) BOOL viewAppeared;

@property (nonatomic) BOOL backSwipeGestureEnabled;

@property (weak, nonatomic, readonly) UIView *contentView;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *keyboardAdjustmentBottomConstraints;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *keyboardAdjustmentTopConstraints;

@property (nonatomic) BOOL isEmbedded;

+ (BOOL)isEmbeddedDefaultValue;

- (void)embeddingViewTapped:(UITapGestureRecognizer*)sender;

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext;

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext;

- (void)addEmbeddingConstraintsToContentView:(UIView*)contentView inView:(UIView*)view;

- (void)awakeAfterInit;

- (CGFloat)constantForKeyboardAdjustmentBottomConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight;

- (CGFloat)constantForKeyboardAdjustmentTopConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight;

- (CGFloat)keyboardAdjustmentForConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight;

@end
