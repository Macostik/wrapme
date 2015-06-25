//
//  WLProfileInformationViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLProfileInformationViewController.h"
#import "WLNavigationHelper.h"
#import "UIButton+Additions.h"
#import "WLKeyboard.h"
#import "WLStillPictureViewController.h"
#import "WLProfileEditSession.h"
#import "WLButton.h"
#import "WLNavigationAnimator.h"

@interface WLProfileInformationViewController () <UITextFieldDelegate, WLStillPictureViewControllerDelegate, WLKeyboardBroadcastReceiver>

@property (strong, nonatomic) IBOutlet WLImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *createImageButton;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) WLUser * user;
@property (strong, nonatomic) IBOutlet WLButton *continueButton;
@property (strong, nonatomic) WLProfileEditSession *editSession;

@end

@implementation WLProfileInformationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.user = [WLUser currentUser];
	
	self.nameTextField.text = self.user.name;
    
    [self.profileImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateEmpty];
    [self.profileImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
    
	self.profileImageView.url = self.user.picture.medium;
    
    self.editSession = [[WLProfileEditSession alloc] initWithUser:self.user];
	
	[self verifyContinueButton];
}

- (IBAction)goToMainScreen:(id)sender {
    __weak typeof(self)weakSelf = self;
	[self updateIfNeeded:^{
        [weakSelf setSuccessStatusAnimated:NO];
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
	WLStillPictureViewController* cameraNavigation = [WLStillPictureViewController instantiate:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    cameraNavigation.delegate = self;
    cameraNavigation.mode = WLStillPictureModeSquare;
    cameraNavigation.animatorPresentationType = WLNavigationAnimatorPresentationTypeModal;
    [self presentViewController:cameraNavigation animated:NO completion:nil];
}

- (void)verifyContinueButton {
	self.continueButton.active = self.editSession.url.nonempty && self.editSession.name.nonempty;
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[controller.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
	WLPicture *picture = [pictures lastObject];
	self.profileImageView.url = picture.medium;
    self.editSession.url = picture.large;
    [self verifyContinueButton];
	[controller.presentingViewController dismissViewControllerAnimated:NO completion:nil];
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

- (IBAction)nameChanged:(id)sender {
    self.editSession.name = self.nameTextField.text;
    [self verifyContinueButton];
}

@end
