//
//  WLActivationViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLActivationViewController.h"
#import "WLAPIManager.h"
#import "WLProfileInformationViewController.h"
#import "UIColor+CustomColors.h"
#import "WLInputAccessoryView.h"
#import "WLSession.h"
#import "UIView+Shorthand.h"
#import "WLProgressBar+WLContribution.h"
#import "UIButton+Additions.h"
#import "NSString+Additions.h"
#import "WLAuthorization.h"
#import "WLAuthorizationRequest.h"
#import "WLHomeViewController.h"
#import "WLNavigation.h"
#import "WLButton.h"
#import "WLVerificationCallRequest.h"
#import "WLSoundPlayer.h"
#import "UIAlertView+Blocks.h"

@interface WLActivationViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *activationTextField;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;
@property (strong, nonatomic) IBOutlet UILabel *phoneNumberLabel;

@end

@implementation WLActivationViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.progressBar.progress = 0;
    self.phoneNumberLabel.text = [[WLAuthorization currentAuthorization] fullPhoneNumber];
    self.activationTextField.text = @"";
}

- (void)activate:(WLBlock)completion failure:(WLFailureBlock)failure {
    [WLSession setConfirmationDate:[NSDate now]];
	NSString* activationCode = self.activationTextField.text;
	if (activationCode.nonempty) {
		__weak typeof(self)weakSelf = self;
		[WLAuthorization currentAuthorization].activationCode = activationCode;
        self.progressBar.operation = [[WLAuthorization currentAuthorization] activate:^(id object) {
            [weakSelf signIn:completion failure:failure];
        } failure:failure];
    } else {
        failure(nil);
    }
}

- (void)signIn:(WLBlock)completion failure:(WLFailureBlock)failure {
    if (self.shouldSignIn) {
        self.progressBar.operation = [[WLAuthorization currentAuthorization] signIn:^(id object) {
            completion();
        } failure:failure];
    } else {
        completion();
    }
}

- (IBAction)next:(WLButton*)sender {
    sender.loading = YES;
    __weak typeof(self)weakSelf = self;
    [self activate:^{
        sender.loading = NO;
        [WLSoundPlayer playSound:WLSound_s01];
        [weakSelf setSuccessStatusAnimated:YES];
    } failure:^(NSError *error) {
        sender.loading = NO;
        [weakSelf setFailureStatusAnimated:YES];
    }];
}

- (IBAction)call:(UIButton*)sender {
    __weak typeof(self)weakSelf = self;
    sender.userInteractionEnabled = NO;
    [[WLVerificationCallRequest request] send:^(id object) {
        sender.userInteractionEnabled = YES;
        [UIAlertView showWithMessage:[NSString stringWithFormat:WLLS(@"Calling %@ now. Please wait."), weakSelf.phoneNumberLabel.text]];
    } failure:^(NSError *error) {
        sender.userInteractionEnabled = YES;
        [error show];
    }];
}

@end
