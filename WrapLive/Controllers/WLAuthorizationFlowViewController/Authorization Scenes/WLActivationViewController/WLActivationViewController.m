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

@interface WLActivationViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *activationTextField;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;
@property (strong, nonatomic) IBOutlet UILabel *phoneNumberLabel;

@end

@implementation WLActivationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.phoneNumberLabel.text = [self.authorization fullPhoneNumber];
}

- (void)activate:(void (^)(void))completion failure:(void (^)(NSError* error))failure {
    [WLSession setConfirmationDate:[NSDate now]];
	NSString* activationCode = self.activationTextField.text;
	if (activationCode.nonempty) {
		__weak typeof(self)weakSelf = self;
		self.authorization.activationCode = activationCode;
        self.progressBar.operation = [self.authorization activate:^(id object) {
            [weakSelf signIn:completion failure:failure];
        } failure:failure];
	}
}

- (void)signIn:(void (^)(void))completion failure:(void (^)(NSError* error))failure {
    self.progressBar.operation = [self.authorization signIn:^(id object) {
        completion();
    } failure:failure];
}

- (IBAction)next:(WLButton*)sender {
    sender.loading = YES;
    __weak typeof(self)weakSelf = self;
    [self activate:^{
        sender.loading = NO;
        [weakSelf.navigationController pushViewController:[WLAuthorizationSceneViewController instantiateWithIdentifier:@"WLVerificationSuccessViewController" storyboard:weakSelf.storyboard] animated:YES];
    } failure:^(NSError *error) {
        sender.loading = NO;
        [weakSelf.navigationController pushViewController:[WLAuthorizationSceneViewController instantiateWithIdentifier:@"WLVerificationFailureViewController" storyboard:weakSelf.storyboard] animated:YES];
    }];
}

- (IBAction)done:(id)sender {
    WLUser *user = [WLUser currentUser];
    if (user.name.nonempty && user.picture.medium.nonempty) {
        [UIWindow mainWindow].rootViewController = [[UIStoryboard storyboardNamed:WLMainStoryboard] instantiateInitialViewController];
    } else {
        WLProfileInformationViewController * controller = [WLProfileInformationViewController instantiate:self.storyboard];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

@end
