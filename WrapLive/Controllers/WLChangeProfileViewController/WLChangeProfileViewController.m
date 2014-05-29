//
//  WLChangeProfileViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 4/24/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChangeProfileViewController.h"
#import "WLCameraViewController.h"
#import "WLNavigation.h"
#import "UIImage+Resize.h"
#import "UIView+Shorthand.h"
#import "WLUser.h"
#import "WLImageFetcher.h"
#import "WLAPIManager.h"
#import "WLKeyboardBroadcaster.h"
#import "WLInputAccessoryView.h"
#import "NSDate+Formatting.h"
#import "WLImageCache.h"
#import "WLSession.h"
#import "NSString+Additions.h"
#import "WLToast.h"
#import "WLWelcomeViewController.h"

@interface WLChangeProfileViewController () <UITextFieldDelegate, WLCameraViewControllerDelegate, WLKeyboardBroadcastReceiver>

@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) WLUser * user;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation WLChangeProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.user = [[WLUser currentUser] copy];
	self.nameTextField.text = self.user.name;
	self.profileImageView.url = self.user.picture.large;
	self.emailTextField.text = self.user.email;
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
}

- (IBAction)back:(UIButton *)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)changeImage:(id)sender {
	WLCameraViewController *controller = [WLCameraViewController instantiate];
	controller.delegate = self;
	controller.defaultPosition = AVCaptureDevicePositionFront;
	controller.mode = WLCameraModeAvatar;
	[self presentViewController:controller animated:YES completion:nil];
}

- (void)saveImage:(UIImage *)image {
	__weak typeof(self)weakSelf = self;
	[[WLImageCache cache] setImage:image completion:^(NSString *path) {
		weakSelf.user.picture.large = path;
		[weakSelf isProfileChanged];
	}];
}

- (IBAction)goToMainScreen:(id)sender {
	__weak typeof(self)weakSelf = self;
	[self updateIfNeeded:^{
		[weakSelf.navigationController popViewControllerAnimated:YES];
	}];
}

- (BOOL)isProfileChanged {
	WLUser* user = self.user;
	WLUser* currentUser = [WLUser currentUser];
	BOOL nameChanged = ![user.name isEqualToString:currentUser.name];
	BOOL avatarChanged = ![user.picture.large isEqualToString:currentUser.picture.large];
	BOOL emailChanged = ![user.email isEqualToString:currentUser.email];
	if (nameChanged || avatarChanged || emailChanged) {
		[self willShowDoneButton:YES];
		return YES;
	} else {
		[self willShowDoneButton:NO];
		return NO;
	}
}

- (void)willShowDoneButton:(BOOL)showDone {
	if (showDone) {
		self.cancelButton.width = self.view.width/2 - 1;
		self.doneButton.x = self.view.width/2;
	} else {
		self.cancelButton.width = self.view.width;
		self.doneButton.x = self.view.width;
	}
}

- (void)updateIfNeeded:(void (^)(void))completion {
	if ([self isProfileChanged]) {
		if ([self.user.email isValidEmail]) {
			self.view.userInteractionEnabled = NO;
			[self.spinner startAnimating];
			__weak typeof(self)weakSelf = self;
			[[WLAPIManager instance] updateMe:self.user success:^(id object) {
				[weakSelf.spinner stopAnimating];
				weakSelf.view.userInteractionEnabled = YES;
				completion();
			} failure:^(NSError *error) {
				[weakSelf.spinner stopAnimating];
				weakSelf.view.userInteractionEnabled = YES;
				[error show];
			}];
		} else {
			[WLToast showWithMessage:@"Your email isn't correct."];
		}
		
	} else {
		completion();
	}
}

- (IBAction)changeAccount:(id)sender {
	[WLSession clear];
	[WLWelcomeViewController instantiateAndMakeRootViewControllerAnimated:YES];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.profileImageView.image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
															  bounds:self.profileImageView.retinaSize
												interpolationQuality:kCGInterpolationDefault];
	[self saveImage:image];
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString* resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	return resultString.length <= WLProfileNameLimit;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == self.nameTextField) {
		self.user.name = self.nameTextField.text;
	} else {
		self.user.email = self.emailTextField.text;
	}
	[self isProfileChanged];
}

#pragma mark - WLKeyboardBroadcastReceiver

- (void)broadcaster:(WLKeyboardBroadcaster *)broadcaster willShowKeyboardWithHeight:(NSNumber *)keyboardHeight {
	__weak typeof(self)weakSelf = self;
	CGAffineTransform transform = self.mainView.transform;
	self.mainView.transform = CGAffineTransformIdentity;
	CGPoint center = [self.view convertPoint:self.nameTextField.center fromView:self.nameTextField.superview];
	CGFloat translation = center.y - (self.view.height - [keyboardHeight floatValue])/2.0f;
	self.mainView.transform = transform;
	[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		weakSelf.mainView.transform = CGAffineTransformMakeTranslation(0, -translation);
	} completion:^(BOOL finished) {}];
}

- (void)broadcasterWillHideKeyboard:(WLKeyboardBroadcaster *)broadcaster {
	__weak typeof(self)weakSelf = self;
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		weakSelf.mainView.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {}];
}

@end
