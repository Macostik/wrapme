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
#import "WLNavigation.h"
#import "UIView+Shorthand.h"
#import "WLImageCache.h"
#import "UIColor+CustomColors.h"
#import "UIImage+Resize.h"
#import "UIButton+Additions.h"
#import "WLImageFetcher.h"
#import "WLKeyboardBroadcaster.h"
#import "NSString+Additions.h"
#import "WLStillPictureViewController.h"
#import "WLEntryManager.h"
#import "WLUpdateUserRequest.h"
#import "WLProfileEditSession.h"
#import "WLButton.h"

@interface WLProfileInformationViewController () <UITextFieldDelegate, WLStillPictureViewControllerDelegate, WLKeyboardBroadcastReceiver>

@property (strong, nonatomic) IBOutlet WLImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *createImageButton;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) WLUser * user;
@property (strong, nonatomic) IBOutlet WLButton *continueButton;
@property (strong, nonatomic) WLProfileEditSession *editSession;

@property (nonatomic) BOOL hasAvatar;

@end

@implementation WLProfileInformationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.user = [WLUser currentUser];
	self.hasAvatar = self.user.name.nonempty;
	
	self.nameTextField.layer.borderWidth = 0.5;
	self.nameTextField.layer.borderColor = [UIColor WL_grayColor].CGColor;
	
	self.nameTextField.text = self.user.name;
	if (!self.hasAvatar) {
		self.profileImageView.url = nil;
		self.profileImageView.image = [UIImage imageNamed:@"default-medium-avatar"];
	} else {
		self.profileImageView.url = self.user.picture.medium;
	}
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
    
    self.editSession = [[WLProfileEditSession alloc] initWithUser:self.user];
	
	[self verifyContinueButton];
}

- (IBAction)goToMainScreen:(id)sender {
	[self updateIfNeeded:^{
		[UIWindow mainWindow].rootViewController = [[UIStoryboard storyboardNamed:WLMainStoryboard] instantiateInitialViewController];
	}];
}

- (void)updateIfNeeded:(void (^)(void))completion {
    if ([self.editSession hasChanges]) {
		self.view.userInteractionEnabled = NO;
        self.continueButton.loading = YES;
        [self.editSession apply];
		__weak typeof(self)weakSelf = self;
        [[WLUpdateUserRequest request:self.user] send:^(id object) {
            weakSelf.continueButton.loading = NO;
			weakSelf.view.userInteractionEnabled = YES;
			completion();
        } failure:^(NSError *error) {
            [weakSelf.editSession reset];
            weakSelf.continueButton.loading = NO;
			weakSelf.view.userInteractionEnabled = YES;
			[error show];
        }];
	} else {
		completion();
	}
}

- (IBAction)createImage:(id)sender {
	WLStillPictureViewController* cameraNavigation = [WLStillPictureViewController instantiate:^(WLStillPictureViewController* controller) {
		controller.delegate = self;
		controller.defaultPosition = AVCaptureDevicePositionFront;
		controller.mode = WLCameraModeAvatar;
	}];
	[self.navigationController.navigationController presentViewController:cameraNavigation animated:YES completion:nil];
}

- (void)saveImage:(UIImage *)image {
    __weak typeof(self)weakSelf = self;
    [[WLImageCache cache] setImage:image completion:^(NSString *path) {
        weakSelf.editSession.url = path;
        [weakSelf verifyContinueButton];
    }];
}

- (void)verifyContinueButton {
	self.continueButton.active = self.hasAvatar && self.editSession.name.nonempty;
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[self.navigationController.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithImage:(UIImage *)image {
	self.hasAvatar = YES;
	self.profileImageView.image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
															  bounds:self.profileImageView.retinaSize
												interpolationQuality:kCGInterpolationDefault];
	[self saveImage:image];
	[self.navigationController.navigationController dismissViewControllerAnimated:YES completion:nil];
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
	self.editSession.name = self.nameTextField.text;
	[self verifyContinueButton];
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return (keyboardHeight - self.continueButton.height)/2.0f;
}

@end
