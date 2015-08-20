//
//  WLBaseViewController.h
//  moji
//
//  Created by Ravenpod on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLKeyboard.h"
#import "GAITrackedViewController.h"
#import <MojiKit/MojiKit.h>

@interface WLBaseViewController : GAITrackedViewController <WLKeyboardBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UIView* navigationBar;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *keyboardAdjustmentLayoutViews;

@property (nonatomic) BOOL keyboardAdjustmentAnimated;

@property (nonatomic) BOOL viewAppeared;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *keyboardAdjustmentBottomConstraints;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *keyboardAdjustmentTopConstraints;

- (void)viewDidLoad:(BOOL)resize;

- (CGFloat)constantForKeyboardAdjustmentBottomConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight;

- (CGFloat)constantForKeyboardAdjustmentTopConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight;

- (CGFloat)keyboardAdjustmentForConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight;

@end
