//
//  WLActivationViewController.m
//  meWrap
//
//  Created by Ravenpod on 3/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLActivationViewController.h"
#import "WLProfileInformationViewController.h"
#import "WLProgressBar+WLContribution.h"
#import "WLHomeViewController.h"
#import "WLButton.h"
#import "WLSoundPlayer.h"

@interface WLActivationViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *activationTextField;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;
@property (strong, nonatomic) IBOutlet UILabel *phoneNumberLabel;

@end

@implementation WLActivationViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.progressBar.progress = 0;
    self.phoneNumberLabel.text = [[Authorization currentAuthorization] fullPhoneNumber];
    self.activationTextField.text = @"";
}

- (void)activate:(Block)completion failure:(FailureBlock)failure {
    [[NSUserDefaults standardUserDefaults] setConfirmationDate:[NSDate now]];
	NSString* activationCode = self.activationTextField.text;
	if (activationCode.nonempty) {
		__weak typeof(self)weakSelf = self;
		[Authorization currentAuthorization].activationCode = activationCode;
        self.progressBar.operation = [[Authorization currentAuthorization] activate:^(id object) {
            [weakSelf signIn:completion failure:failure];
        } failure:failure];
    } else {
        failure(nil);
    }
}

- (void)signIn:(Block)completion failure:(FailureBlock)failure {
    if (self.shouldSignIn) {
        self.progressBar.operation = [[Authorization currentAuthorization] signIn:^(id object) {
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
        [weakSelf setSuccessStatusAnimated:NO];
    } failure:^(NSError *error) {
        sender.loading = NO;
        [weakSelf setFailureStatusAnimated:NO];
    }];
}

- (IBAction)call:(UIButton*)sender {
    __weak typeof(self)weakSelf = self;
    sender.userInteractionEnabled = NO;
    [[WLAPIRequest verificationCall] send:^(id object) {
        sender.userInteractionEnabled = YES;
        [[UIAlertController alert:[NSString stringWithFormat:@"formatted_calling_now".ls, weakSelf.phoneNumberLabel.text]] show];
    } failure:^(NSError *error) {
        sender.userInteractionEnabled = YES;
        [error show];
    }];
}

@end
