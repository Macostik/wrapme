//
//  WLActivationViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLActivationViewController.h"
#import "WLUser.h"
#import "WLAPIManager.h"
#import "WLProfileInformationViewController.h"
#import "UIColor+CustomColors.h"
#import "WLInputAccessoryView.h"

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
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UILabel *phoneNumberLabel;

@property (nonatomic) WLActivationPage currentPage;

@end

@implementation WLActivationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	[WLInputAccessoryView inputAccessoryViewWithResponder:self.activationTextField];
	
	self.phoneNumberLabel.text = [NSString stringWithFormat:@"+%@ %@", self.currentUser.countryCallingCode, self.currentUser.phoneNumber];
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
	self.currentPage = WLActivationPageInProgress;
	__weak typeof(self)weakSelf = self;
	[self activate:^{
		weakSelf.currentPage = WLActivationPageSuccess;
	} failure:^(NSError *error) {
		weakSelf.currentPage = WLActivationPageFailure;
	}];
}

- (void)activate:(void (^)(void))completion failure:(void (^)(NSError* error))failure {
	__weak typeof(self)weakSelf = self;
	self.currentUser.activationCode = self.activationTextField.text;
	id operation = [[WLAPIManager instance] activate:self.currentUser success:^(id object) {
		[weakSelf signIn:completion failure:failure];
	} failure:failure];
	[self handleProgressOfOperation:operation];
}

- (void)signIn:(void (^)(void))completion failure:(void (^)(NSError* error))failure {
	id operation = [[WLAPIManager instance] signIn:self.currentUser success:^(id object) {
		completion();
	} failure:failure];
	[self handleProgressOfOperation:operation];
}

- (void)handleProgressOfOperation:(AFHTTPRequestOperation*)operation {
	__weak typeof(self)weakSelf = self;
	[operation setUploadProgressBlock:^(NSUInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
		float progress = ((float)totalBytesWritten/(float)totalBytesExpectedToWrite);
		[weakSelf.progressView setProgress:progress animated:YES];
	}];
	[operation setDownloadProgressBlock:^(NSUInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
		float progress = ((float)totalBytesRead/(float)totalBytesExpectedToRead);
		[weakSelf.progressView setProgress:progress animated:YES];
	}];
}

- (IBAction)editNumber:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)tryAgain:(id)sender {
	self.activationTextField.text = nil;
	self.currentPage = WLActivationPageEntering;
}

- (IBAction)continue:(id)sender {
	WLProfileInformationViewController * controller = [WLProfileInformationViewController new];
	[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	CGFloat translation = textField.frame.origin.y - textField.frame.size.height - 5;
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -translation);
	[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.view.transform = transform;
	} completion:^(BOOL finished) {}];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.view.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {}];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString* resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	return resultString.length <= WLActivationCodeLimit;
}

@end
