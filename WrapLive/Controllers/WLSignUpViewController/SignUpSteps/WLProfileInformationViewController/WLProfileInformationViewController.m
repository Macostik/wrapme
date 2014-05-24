//
//  WLProfileInformationViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLProfileInformationViewController.h"
#import "WLHomeViewController.h"
#import "WLCameraViewController.h"
#import "WLAPIManager.h"
#import "WLUser.h"
#import "UIStoryboard+Additions.h"
#import "UIView+Shorthand.h"
#import "WLImageCache.h"
#import "UIColor+CustomColors.h"
#import "UIImage+Resize.h"
#import "UIButton+Additions.h"
#import "WLImageFetcher.h"
#import "WLKeyboardBroadcaster.h"
#import "NSString+Additions.h"

@interface WLProfileInformationViewController () <UITextFieldDelegate, WLCameraViewControllerDelegate, WLKeyboardBroadcastReceiver>

@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *createImageButton;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) WLUser * user;
@property (nonatomic, readonly) UIViewController* signUpViewController;
@property (strong, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *mainView;

@property (nonatomic) BOOL hasAvatar;

@end

@implementation WLProfileInformationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.user = [[WLUser currentUser] copy];
	self.hasAvatar = self.user.name.nonempty;
	[self verifyContinueButton];
	self.nameTextField.layer.borderWidth = 0.5;
	self.nameTextField.layer.borderColor = [UIColor WL_grayColor].CGColor;
	
	self.nameTextField.text = self.user.name;
	self.profileImageView.url = self.user.picture.medium;
	
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
}

- (UIViewController *)signUpViewController {
	return self.navigationController.parentViewController;
}

- (IBAction)goToMainScreen:(id)sender {
	__weak typeof(self)weakSelf = self;
	[self updateIfNeeded:^{
		NSArray *navigationArray = @[[weakSelf.signUpViewController.storyboard homeViewController]];
		[weakSelf.signUpViewController.navigationController setViewControllers:navigationArray animated:YES];
	}];
}

- (void)updateIfNeeded:(void (^)(void))completion {
	WLUser* user = self.user;
	WLUser* currentUser = [WLUser currentUser];
	BOOL nameChanged = ![user.name isEqualToString:currentUser.name];
	BOOL avatarChanged = ![user.picture.large isEqualToString:currentUser.picture.large];
	if (nameChanged || avatarChanged) {
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
		completion();
	}
}

- (IBAction)createImage:(id)sender {
	WLCameraViewController * controller = [self.signUpViewController.storyboard cameraViewController];
	controller.delegate = self;
	controller.defaultPosition = AVCaptureDevicePositionFront;
	controller.mode = WLCameraModeAvatar;
	[self.signUpViewController presentViewController:controller animated:YES completion:nil];
}

- (void)saveImage:(UIImage *)image {
	__weak typeof(self)weakSelf = self;
	[[WLImageCache cache] setImage:image completion:^(NSString *path) {
		weakSelf.user.picture.large = path;
	}];
	[self verifyContinueButton];
}

- (void)verifyContinueButton {
	self.continueButton.active = (self.user.name.nonempty) && self.hasAvatar;
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self.signUpViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.hasAvatar = YES;
	self.profileImageView.image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
															  bounds:self.profileImageView.retinaSize
												interpolationQuality:kCGInterpolationDefault];
	[self saveImage:image];
	[self.signUpViewController dismissViewControllerAnimated:YES completion:nil];
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
	self.user.name = self.nameTextField.text;
	[self verifyContinueButton];
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
