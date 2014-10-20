//
//  WLBaseViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"
#import "WLKeyboardBroadcaster.h"
#import "NSArray+Additions.h"
#import "UIView+AnimationHelper.h"

@interface WLBaseViewController ()

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *keyboardAdjustmentBottomConstraints;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *keyboardAdjustmentTopConstraints;

@property (strong, nonatomic) NSMapTable* keyboardAdjustmentDefaultConstants;

@end

@implementation WLBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.keyboardAdjustmentDefaultConstants = [NSMapTable strongToStrongObjectsMapTable];
    [[WLKeyboardBroadcaster broadcaster] addReceiver:self];
}

#pragma mark - WLKeyboardBroadcastReceiver

- (void)broadcaster:(WLKeyboardBroadcaster *)broadcaster willShowKeyboardWithHeight:(NSNumber *)keyboardHeight {
    if (!self.keyboardAdjustmentTopConstraints.nonempty || !self.keyboardAdjustmentBottomConstraints.nonempty) return;
    NSMapTable *constants = self.keyboardAdjustmentDefaultConstants;
    if ([constants count] == 0) {
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
            CGFloat constant = constraint.constant;
            constraint.constant = constant - [keyboardHeight floatValue];
            [constants setObject:@(constant) forKey:constraint];
        }
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
            CGFloat constant = constraint.constant;
            constraint.constant = constant + [keyboardHeight floatValue];
            [constants setObject:@(constant) forKey:constraint];
        }
    } else {
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
            CGFloat constant = [[constants objectForKey:constraint] floatValue];
            constraint.constant = constant - [keyboardHeight floatValue];
        }
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
            CGFloat constant = [[constants objectForKey:constraint] floatValue];
            constraint.constant = constant + [keyboardHeight floatValue];
        }
    }
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:YES animation:^{
        [UIView setAnimationCurve:[broadcaster.animationCurve integerValue]];
        [weakSelf.view layoutIfNeeded];
    }];
}

- (void)broadcasterWillHideKeyboard:(WLKeyboardBroadcaster *)broadcaster {
    NSMapTable *constants = self.keyboardAdjustmentDefaultConstants;
    for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
        constraint.constant = [[constants objectForKey:constraint] floatValue];
    }
    for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
        constraint.constant = [[constants objectForKey:constraint] floatValue];
    }
    [self.keyboardAdjustmentDefaultConstants removeAllObjects];
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:YES animation:^{
        [UIView setAnimationCurve:[broadcaster.animationCurve integerValue]];
        [weakSelf.view layoutIfNeeded];
    }];
}

@end
