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
#import "UIImage+WLStoring.h"
#import "UIColor+CustomColors.h"
#import "UIImage+Resize.h"
#import "UIButton+Additions.h"
#import "UIImageView+ImageLoading.h"

static NSInteger WLProfileNameLimit = 40;

@interface WLProfileInformationViewController () <UITextFieldDelegate, WLCameraViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *createImageButton;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) WLUser * user;
@property (nonatomic, readonly) UIViewController* signUpViewController;
@property (strong, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *mainView;

@end

@implementation WLProfileInformationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.user = [[WLUser currentUser] copy];
	[self verifyContinueButton];
	self.nameTextField.layer.borderWidth = 0.5;
	self.nameTextField.layer.borderColor = [UIColor WL_grayColor].CGColor;
	
	self.nameTextField.text = self.user.name;
	self.profileImageView.imageUrl = self.user.picture.medium;
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
	controller.mode = WLCameraMode200x200;
	[self.signUpViewController presentViewController:controller animated:YES completion:nil];
}

- (void)saveImage:(UIImage *)image {
	__weak typeof(self)weakSelf = self;
	[image storeAsAvatar:^(NSString *path) {
		weakSelf.user.picture.large = path;
	}];
	[self verifyContinueButton];
}

- (void)verifyContinueButton {
	self.continueButton.active = self.user.name.length > 0;
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self.signUpViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
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

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	CGFloat translation = textField.y - 0.5 * (self.view.height - 216 - textField.height);
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -translation);
	[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.mainView.transform = transform;
	} completion:^(BOOL finished) {}];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	self.user.name = self.nameTextField.text;
	[self verifyContinueButton];
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.mainView.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {}];
}

@end
