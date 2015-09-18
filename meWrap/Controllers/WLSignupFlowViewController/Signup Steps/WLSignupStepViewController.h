//
//  WLAuthorizationSceneViewController.h
//  meWrap
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"
#import "WLAuthorizationRequest.h"

typedef NS_ENUM(NSUInteger, WLSignupStepStatus) {
    WLSignupStepStatusSuccess,
    WLSignupStepStatusFailure,
    WLSignupStepStatusCancel
};

@class WLSignupStepViewController;

typedef WLSignupStepViewController *(^WLSignupStepCompletionBlock)(void);
typedef WLSignupStepViewController *(^WLSignupVerificationStepBlock) (WLSignupStepCompletionBlock successBlock, BOOL shouldSignIn);
typedef WLSignupStepViewController *(^WLSignupLinkDeviceStepBlock) (BOOL shouldSendPasscode);

@interface WLSignupStepViewController : WLBaseViewController

@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

- (void)setCompletionBlock:(WLSignupStepCompletionBlock)block forStatus:(NSUInteger)status;

- (void)setSuccessStatusBlock:(WLSignupStepCompletionBlock)block;

- (void)setFailureStatusBlock:(WLSignupStepCompletionBlock)block;

- (void)setCancelStatusBlock:(WLSignupStepCompletionBlock)block;

- (WLSignupStepCompletionBlock)completionBlockForStatus:(NSUInteger)status;

- (BOOL)setStatus:(NSUInteger)status animated:(BOOL)animated;

- (BOOL)setSuccessStatusAnimated:(BOOL)animated;

- (BOOL)setFailureStatusAnimated:(BOOL)animated;

- (BOOL)setCancelStatusAnimated:(BOOL)animated;

@end
