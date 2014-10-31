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

static NSInteger WLActivationCodeLimit = 4;

typedef NS_ENUM(NSInteger, WLActivationPage) {
	WLActivationPageEntering,
	WLActivationPageInProgress,
	WLActivationPageSuccess,
	WLActivationPageFailure
};

@interface WLActivationViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *activationTextField;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *activationViews;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;
@property (strong, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;

@property (nonatomic) WLActivationPage currentPage;

@end

@implementation WLActivationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.activationTextField.inputAccessoryView = [WLInputAccessoryView inputAccessoryViewWithTarget:self
																							  cancel:@selector(activationCancel:)
																								done:@selector(activationDone:)];
	
	self.phoneNumberLabel.text = [self.authorization fullPhoneNumber];
	self.activationTextField.layer.borderWidth = 0.5;
	self.activationTextField.layer.borderColor = [UIColor WL_grayColor].CGColor;
	self.continueButton.active = NO;
}

- (void)activationCancel:(id)sender {
	[self.activationTextField resignFirstResponder];
}

- (void)activationDone:(id)sender {
	[self activateCode];
	[self.activationTextField resignFirstResponder];
}

- (void)setCurrentPage:(WLActivationPage)currentPage {
	[self setCurrentPage:currentPage animated:NO];
}

- (void)setCurrentPage:(WLActivationPage)currentPage animated:(BOOL)animated {
	_currentPage = currentPage;
	for (UIView* view in self.activationViews) {
		NSInteger index = [self.activationViews indexOfObject:view];
		view.hidden = (index != currentPage);
	}
}

- (IBAction)activateCode:(id)sender {
	[self activateCode];
}

- (void)activateCode {
	if (self.activationTextField.text.length == WLActivationCodeLimit) {
		self.currentPage = WLActivationPageInProgress;
		__weak typeof(self)weakSelf = self;
		[self activate:^{
			weakSelf.currentPage = WLActivationPageSuccess;
		} failure:^(NSError *error) {
			weakSelf.currentPage = WLActivationPageFailure;
		}];
	}
}

- (void)activate:(void (^)(void))completion failure:(void (^)(NSError* error))failure {
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

- (IBAction)editNumber:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)tryAgain:(id)sender {
	self.activationTextField.text = nil;
	self.continueButton.active = NO;
	self.currentPage = WLActivationPageEntering;
}

- (IBAction)done:(id)sender {
    if ([WLUser currentUser].name.nonempty) {
        [UIWindow mainWindow].rootViewController = [[UIStoryboard storyboardNamed:WLMainStoryboard] instantiateInitialViewController];
    } else {
        WLProfileInformationViewController * controller = [WLProfileInformationViewController instantiate:[UIStoryboard storyboardNamed:WLSignUpStoryboard]];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	self.continueButton.active = sender.text.length == WLActivationCodeLimit;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString* resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	return resultString.length <= WLActivationCodeLimit;
}

@end
