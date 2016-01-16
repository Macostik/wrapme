//
//  WLBaseViewController.h
//  meWrap
//
//  Created by Ravenpod on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"

@protocol KeyboardNotifying;

@interface WLBaseViewController : GAITrackedViewController <KeyboardNotifying>

@property (nonatomic) CGRect preferredViewFrame;

@property (weak, nonatomic) IBOutlet UIView* navigationBar;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *keyboardAdjustmentLayoutViews;

@property (nonatomic) BOOL keyboardAdjustmentAnimated;

@property (nonatomic) BOOL viewAppeared;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *keyboardAdjustmentBottomConstraints;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *keyboardAdjustmentTopConstraints;

+ (NSString*)lastAppearedScreenName;

- (BOOL)shouldUsePreferredViewFrame;

- (CGFloat)constantForKeyboardAdjustmentBottomConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight;

- (CGFloat)constantForKeyboardAdjustmentTopConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight;

- (CGFloat)keyboardAdjustmentForConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight;

@end
