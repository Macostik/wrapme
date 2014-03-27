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
#import "WLSession.h"
#import "UIStoryboard+Additions.h"

@interface WLProfileInformationViewController () <UITextFieldDelegate, WLCameraViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *createImageButton;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) WLUser * user;
@property (nonatomic, readonly) UIViewController* signUpViewController;
@property (strong, nonatomic) IBOutlet UIButton *continueButton;

@end

@implementation WLProfileInformationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.user = [WLSession user];
	[self verifyContinueButton];
}

- (UIViewController *)signUpViewController {
	return self.navigationController.parentViewController;
}

- (IBAction)goToMainScreen:(id)sender {
	self.view.userInteractionEnabled = NO;
	[self sendUpdateRequest];
}

- (void)sendUpdateRequest {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] updateMe:self.user success:^(id object) {
		[WLSession setUser:weakSelf.user];
		NSArray *navigationArray = @[[weakSelf.signUpViewController.storyboard homeViewController]];
		[weakSelf.signUpViewController.navigationController setViewControllers:navigationArray animated:YES];
	} failure:^(NSError *error) {
		weakSelf.view.userInteractionEnabled = YES;
		[error show];
	}];
}

- (IBAction)createImage:(id)sender {
	WLCameraViewController * controller = [self.signUpViewController.storyboard cameraViewController];
	controller.delegate = self;
	[self.signUpViewController presentViewController:controller animated:YES completion:nil];
}

- (void)saveImage:(UIImage *)image {
	NSString  *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/WrapLiveAvatar.jpg"];
	[UIImageJPEGRepresentation(image,1.0) writeToFile:path atomically:YES];
	self.user.avatar = path;
	[self verifyContinueButton];
}

- (void)verifyContinueButton {
	self.continueButton.enabled = (self.user.avatar) && (self.user.name) ? YES : NO;
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self.signUpViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.profileImageView.image = image;
	[self saveImage:image];
	[self.signUpViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	CGFloat translation = textField.frame.origin.y - 0.5 * (self.view.frame.size.height - 216 - textField.frame.size.height);
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -translation);
	[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.view.transform = transform;
	} completion:^(BOOL finished) {}];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	self.user.name = self.nameTextField.text;
	[self verifyContinueButton];
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.view.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {}];
}

@end
