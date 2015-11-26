//
//  WLProfileInformationViewController.m
//  meWrap
//
//  Created by Ravenpod on 3/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProfileInformationViewController.h"
#import "WLKeyboard.h"
#import "WLStillPictureViewController.h"
#import "WLButton.h"
#import "WLImageView.h"

@interface WLProfileInformationViewController () <UITextFieldDelegate, WLStillPictureViewControllerDelegate, WLKeyboardBroadcastReceiver>

@property (strong, nonatomic) IBOutlet WLImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *createImageButton;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UILabel *addPhotoLabel;
@property (weak, nonatomic) User * user;
@property (strong, nonatomic) IBOutlet WLButton *continueButton;
@property (strong, nonatomic) ProfileEditSession *editSession;

@end

@implementation WLProfileInformationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.user = [User currentUser];
	
	self.nameTextField.text = self.user.name;
    
	self.profileImageView.url = self.user.picture.large;
    
    self.editSession = [[ProfileEditSession alloc] initWithUser:self.user];
	
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
        [[WLAPIRequest updateUser:self.user email:nil] send:^(id object) {
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
	WLStillPictureViewController* cameraNavigation = [WLStillPictureViewController stillAvatarViewController];
    cameraNavigation.delegate = self;
    cameraNavigation.mode = WLStillPictureModeSquare;
    [self presentViewController:cameraNavigation animated:NO completion:nil];
}

- (void)verifyContinueButton {
	self.continueButton.active = self.editSession.avatarSession.hasValidChanges && self.editSession.nameSession.hasValidChanges;
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[controller.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
	Asset *picture = [[pictures lastObject] uploadablePicture:NO];
	self.profileImageView.url = picture.large;
    self.editSession.avatarSession.changedValue = picture.large;
    [self verifyContinueButton];
    self.addPhotoLabel.hidden = picture.medium.nonempty;
	[controller.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString* resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	return resultString.length <= [Constants profileNameLimit];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	self.editSession.nameSession.changedValue = self.nameTextField.text;
	[self verifyContinueButton];
}

- (IBAction)nameChanged:(id)sender {
    self.editSession.nameSession.changedValue = self.nameTextField.text;
    [self verifyContinueButton];
}

@end
