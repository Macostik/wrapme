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
    [[WLKeyboardBroadcaster broadcaster] addReceiver:self];
}

#pragma mark - WLKeyboardBroadcastReceiver

- (void)updateKeyboardAdjustmentConstraints:(CGFloat)keyboardHeight {
    NSMapTable *constants = self.keyboardAdjustmentDefaultConstants;
    for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
        CGFloat constant = [[constants objectForKey:constraint] floatValue];
        constraint.constant = constant - keyboardHeight;
    }
    for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
        CGFloat constant = [[constants objectForKey:constraint] floatValue];
        constraint.constant = constant + keyboardHeight;
    }
}

- (void)broadcaster:(WLKeyboardBroadcaster *)broadcaster willShowKeyboardWithHeight:(NSNumber *)keyboardHeight {
    if (!self.keyboardAdjustmentTopConstraints.nonempty || !self.keyboardAdjustmentBottomConstraints.nonempty) return;
    NSMapTable *constants = self.keyboardAdjustmentDefaultConstants;
    if ([constants count] == 0) {
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
            [constants setObject:@(constraint.constant) forKey:constraint];
        }
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
            [constants setObject:@(constraint.constant) forKey:constraint];
        }
    }
    
    [self updateKeyboardAdjustmentConstraints:[keyboardHeight floatValue]];
    
    __weak typeof(self)weakSelf = self;
    [broadcaster performAnimation:^{
        [weakSelf.view layoutIfNeeded];
    }];
}

- (void)broadcasterWillHideKeyboard:(WLKeyboardBroadcaster *)broadcaster {
    if (!self.keyboardAdjustmentTopConstraints.nonempty || !self.keyboardAdjustmentBottomConstraints.nonempty) return;
    [self updateKeyboardAdjustmentConstraints:0];
    [self.keyboardAdjustmentDefaultConstants removeAllObjects];
    __weak typeof(self)weakSelf = self;
    [broadcaster performAnimation:^{
        [weakSelf.view layoutIfNeeded];
    }];
}

@end
