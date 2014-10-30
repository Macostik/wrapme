//
//  WLBaseViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"
#import "NSArray+Additions.h"
#import "UIView+AnimationHelper.h"
#import "WLNavigation.h"

@interface WLBaseViewController ()

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *keyboardAdjustmentBottomConstraints;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *keyboardAdjustmentTopConstraints;

@property (strong, nonatomic) NSMapTable* keyboardAdjustmentDefaultConstants;

@end

@implementation WLBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = [UIWindow mainWindow].bounds;
    [self.view layoutIfNeeded];
    self.keyboardAdjustmentDefaultConstants = [NSMapTable strongToStrongObjectsMapTable];
    [[WLKeyboard keyboard] addReceiver:self];
}

#pragma mark - WLKeyboardBroadcastReceiver

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight;
}

- (NSArray *)keyboardAdjustmentLayoutViews {
    if (!_keyboardAdjustmentLayoutViews.nonempty) {
        _keyboardAdjustmentLayoutViews = @[self.view];
    }
    return _keyboardAdjustmentLayoutViews;
}

- (BOOL)updateKeyboardAdjustmentConstraints:(CGFloat)adjustment {
    BOOL changed = NO;
    NSMapTable *constants = self.keyboardAdjustmentDefaultConstants;
    for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
        CGFloat constant = [[constants objectForKey:constraint] floatValue];
        constant -= adjustment;
        if (constraint.constant != constant) {
            constraint.constant = constant;
            changed = YES;
        }
    }
    for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
        CGFloat constant = [[constants objectForKey:constraint] floatValue];
        constant += adjustment;
        if (constraint.constant != constant) {
            constraint.constant = constant;
            changed = YES;
        }
    }
    return changed;
}

- (void)keyboardWillShow:(WLKeyboard *)keyboard {
    if (!self.keyboardAdjustmentTopConstraints.nonempty && !self.keyboardAdjustmentBottomConstraints.nonempty) return;
    NSMapTable *constants = self.keyboardAdjustmentDefaultConstants;
    if ([constants count] == 0) {
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
            [constants setObject:@(constraint.constant) forKey:constraint];
        }
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
            [constants setObject:@(constraint.constant) forKey:constraint];
        }
    }
    
    CGFloat adjustment = [self keyboardAdjustmentValueWithKeyboardHeight:keyboard.height];
    if ([self updateKeyboardAdjustmentConstraints:adjustment]) {
        __weak typeof(self)weakSelf = self;
        [keyboard performAnimation:^{
            for (UIView *layoutView in weakSelf.keyboardAdjustmentLayoutViews) {
                [layoutView layoutIfNeeded];
            }
        }];
    }
}

- (void)keyboardWillHide:(WLKeyboard *)keyboard {
    if (!self.keyboardAdjustmentTopConstraints.nonempty && !self.keyboardAdjustmentBottomConstraints.nonempty) return;
    [self updateKeyboardAdjustmentConstraints:0];
    [self.keyboardAdjustmentDefaultConstants removeAllObjects];
    __weak typeof(self)weakSelf = self;
    [keyboard performAnimation:^{
        for (UIView *layoutView in weakSelf.keyboardAdjustmentLayoutViews) {
            [layoutView layoutIfNeeded];
        }
    }];
}

@end
