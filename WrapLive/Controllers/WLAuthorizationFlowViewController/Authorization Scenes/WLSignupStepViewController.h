//
//  WLAuthorizationSceneViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

typedef NS_ENUM(NSUInteger, WLSignupStepStatus) {
    WLSignupStepStatusSuccess,
    WLSignupStepStatusFailure,
    WLSignupStepStatusCancel
};

@class WLSignupStepViewController;

@protocol WLAuthorizationSceneViewControllerDelegate <NSObject>

@end

@interface WLSignupStepViewController : WLBaseViewController

@property (nonatomic, weak) id <WLAuthorizationSceneViewControllerDelegate> delegate;

- (void)setViewController:(WLSignupStepViewController *)controller forStatus:(NSUInteger)status;

- (void)setSuccessViewController:(WLSignupStepViewController*)controller;

- (void)setFailureViewController:(WLSignupStepViewController*)controller;

- (void)setCancelViewController:(WLSignupStepViewController*)controller;

- (WLSignupStepViewController*)viewControllerForStatus:(NSUInteger)status;

- (BOOL)showViewControllerForStatus:(NSUInteger)status animated:(BOOL)animated;

- (BOOL)showSuccessViewControllerAnimated:(BOOL)animated;

- (BOOL)showFailureViewControllerAnimated:(BOOL)animated;

- (BOOL)showCancelViewControllerAnimated:(BOOL)animated;

- (void)complete;

@end
