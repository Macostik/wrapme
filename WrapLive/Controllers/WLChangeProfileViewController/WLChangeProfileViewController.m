//
//  WLChangeProfileViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 4/24/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChangeProfileViewController.h"
#import "WLCameraViewController.h"
#import "UIStoryboard+Additions.h"
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

@interface WLChangeProfileViewController () <UITextFieldDelegate, WLCameraViewControllerDelegate, WLKeyboardBroadcastReceiver>

@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *birthdateTextField;
@property (strong, nonatomic) UIDatePicker * birthdatePicker;
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
	[self setupPicker];
	self.nameTextField.text = self.user.name;
	self.profileImageView.url = self.user.picture.large;
	self.birthdateTextField.text = [self.birthdatePicker.date GMTStringWithFormat:@"MMM' 'dd', 'yyyy'"];
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
}

- (IBAction)back:(UIButton *)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)changeImage:(id)sender {
	WLCameraViewController * controller = [self.storyboard cameraViewController];
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

- (void)setupPicker {
	self.birthdatePicker = [UIDatePicker new];
	self.birthdatePicker.datePickerMode = UIDatePickerModeDate;
	self.birthdatePicker.maximumDate = [NSDate date];
	self.birthdatePicker.backgroundColor = [UIColor whiteColor];
	self.birthdatePicker.date = self.user.birthdate;
	self.birthdatePicker.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	self.birthdateTextField.inputAccessoryView = [WLInputAccessoryView inputAccessoryViewWithTarget:self cancel:@selector(birthdatePickerCancel:) done:@selector(birthdatePickerDone:)];
	self.birthdateTextField.inputView = self.birthdatePicker;
}

- (void)birthdatePickerCancel:(id)sender {
	[self.birthdateTextField resignFirstResponder];
}

- (void)birthdatePickerDone:(id)sender {
	self.birthdateTextField.text = [self.birthdatePicker.date GMTStringWithFormat:@"MMM' 'dd', 'yyyy'"];
	self.user.birthdate = self.birthdatePicker.date;
	[self isProfileChanged];
	[self.birthdateTextField resignFirstResponder];
}

- (BOOL)isProfileChanged {
	WLUser* user = self.user;
	WLUser* currentUser = [WLUser currentUser];
	BOOL nameChanged = ![user.name isEqualToString:currentUser.name];
	BOOL avatarChanged = ![user.picture.large isEqualToString:currentUser.picture.large];
	BOOL birthdateChanged = ![user.birthdate isEqualToDate:currentUser.birthdate];
	if (nameChanged || avatarChanged || birthdateChanged) {
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

- (IBAction)changeAccount:(id)sender {
	[WLSession clear];
	[self.navigationController setViewControllers:@[[self.storyboard welcomeViewController]] animated:YES];
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
	self.user.name = self.nameTextField.text;
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
