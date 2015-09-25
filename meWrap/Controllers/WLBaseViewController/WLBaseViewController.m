//
//  WLBaseViewController.m
//  meWrap
//
//  Created by Ravenpod on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"
#import "UIView+AnimationHelper.h"
#import "WLNavigationHelper.h"
#import "NSObject+NibAdditions.h"

@interface WLBaseViewController ()

@property (strong, nonatomic) NSMapTable* keyboardAdjustmentDefaultConstants;

@end

@implementation WLBaseViewController

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%@ dealloc", NSStringFromClass(self.class));
#endif
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.preferredViewFrame = [UIWindow mainWindow].bounds;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.preferredViewFrame = [UIWindow mainWindow].bounds;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.preferredViewFrame = [UIWindow mainWindow].bounds;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)loadView {
    [super loadView];
    if ([self shouldUsePreferredViewFrame]) {
        self.view.frame = self.preferredViewFrame;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self shouldUsePreferredViewFrame]) {
        [self.view layoutIfNeeded];
    }
    self.screenName = NSStringFromClass([self class]);
    self.keyboardAdjustmentAnimated = YES;
    [[WLKeyboard keyboard] addReceiver:self];
}

- (BOOL)shouldUsePreferredViewFrame {
    return YES;
}

- (NSMapTable *)keyboardAdjustmentDefaultConstants {
    NSMapTable *constants = _keyboardAdjustmentDefaultConstants;
    if (!constants) {
        constants = [NSMapTable strongToStrongObjectsMapTable];
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
            [constants setObject:@(constraint.constant) forKey:constraint];
        }
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
            [constants setObject:@(constraint.constant) forKey:constraint];
        }
        _keyboardAdjustmentDefaultConstants = constants;
    }
    return constants;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewAppeared = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.viewAppeared = NO;
}

#pragma mark - WLKeyboardBroadcastReceiver

- (CGFloat)constantForKeyboardAdjustmentBottomConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    CGFloat adjustment = [self keyboardAdjustmentForConstraint:constraint defaultConstant:defaultConstant keyboardHeight:keyboardHeight];
    return defaultConstant + adjustment;
}

- (CGFloat)constantForKeyboardAdjustmentTopConstraint:(NSLayoutConstraint*)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    CGFloat adjustment = [self keyboardAdjustmentForConstraint:constraint defaultConstant:defaultConstant keyboardHeight:keyboardHeight];
    return defaultConstant - adjustment;
}

- (CGFloat)keyboardAdjustmentForConstraint:(NSLayoutConstraint *)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight;
}

- (NSArray *)keyboardAdjustmentLayoutViews {
    if (!_keyboardAdjustmentLayoutViews.nonempty) {
        _keyboardAdjustmentLayoutViews = @[self.view];
    }
    return _keyboardAdjustmentLayoutViews;
}

- (BOOL)updateKeyboardAdjustmentConstraints:(CGFloat)keyboardHeight {
    BOOL changed = NO;
    NSMapTable *constants = self.keyboardAdjustmentDefaultConstants;
    for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
        CGFloat constant = [[constants objectForKey:constraint] floatValue];
        if (keyboardHeight > 0) {
            constant = [self constantForKeyboardAdjustmentTopConstraint:constraint defaultConstant:constant keyboardHeight:keyboardHeight];
        }
        if (constraint.constant != constant) {
            constraint.constant = constant;
            changed = YES;
        }
    }
    for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
        CGFloat constant = [[constants objectForKey:constraint] floatValue];
        if (keyboardHeight > 0) {
            constant = [self constantForKeyboardAdjustmentBottomConstraint:constraint defaultConstant:constant keyboardHeight:keyboardHeight];
        }
        if (constraint.constant != constant) {
            constraint.constant = constant;
            changed = YES;
        }
    }
    return changed;
}

- (void)keyboardWillShow:(WLKeyboard *)keyboard {
    if (!self.isViewLoaded || (!self.keyboardAdjustmentTopConstraints.nonempty && !self.keyboardAdjustmentBottomConstraints.nonempty)) return;
    if ([self updateKeyboardAdjustmentConstraints:keyboard.height]) {
        if (self.keyboardAdjustmentAnimated && self.viewAppeared) {
            __weak typeof(self)weakSelf = self;
            [keyboard performAnimation:^{
                for (UIView *layoutView in weakSelf.keyboardAdjustmentLayoutViews) {
                    [layoutView layoutIfNeeded];
                }
            }];
        } else {
            for (UIView *layoutView in self.keyboardAdjustmentLayoutViews) {
                [layoutView layoutIfNeeded];
            }
        }
    }
}

- (void)keyboardDidShow:(WLKeyboard *)keyboard {
    
}

- (void)keyboardWillHide:(WLKeyboard *)keyboard {
    if (!self.isViewLoaded || (!self.keyboardAdjustmentTopConstraints.nonempty && !self.keyboardAdjustmentBottomConstraints.nonempty)) return;
    [self updateKeyboardAdjustmentConstraints:0];
    self.keyboardAdjustmentDefaultConstants = nil;
    if (self.keyboardAdjustmentAnimated && self.viewAppeared) {
        __weak typeof(self)weakSelf = self;
        [keyboard performAnimation:^{
            for (UIView *layoutView in weakSelf.keyboardAdjustmentLayoutViews) {
                [layoutView layoutIfNeeded];
            }
        }];
    } else {
        for (UIView *layoutView in self.keyboardAdjustmentLayoutViews) {
            [layoutView layoutIfNeeded];
        }
    }
}

- (void)keyboardDidHide:(WLKeyboard *)keyboard {
    
}

@end
