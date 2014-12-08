//
//  WLChangeProfileViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 4/24/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChangeProfileViewController.h"
#import "WLCameraViewController.h"
#import "WLStillPictureViewController.h"
#import "WLNavigation.h"
#import "UIImage+Resize.h"
#import "UIView+Shorthand.h"
#import "WLImageFetcher.h"
#import "WLAPIManager.h"
#import "WLKeyboard.h"
#import "WLInputAccessoryView.h"
#import "NSDate+Formatting.h"
#import "WLImageCache.h"
#import "WLSession.h"
#import "NSString+Additions.h"
#import "WLToast.h"
#import "WLWelcomeViewController.h"
#import "WLEntryManager.h"
#import "UIButton+Additions.h"
#import "WLProfileEditSession.h"
#import "WLUpdateUserRequest.h"
#import "UIView+AnimationHelper.h"
#import "WLEntryNotifier.h"
#import "WLResendConfirmationRequest.h"

@interface WLChangeProfileViewController () <WLKeyboardBroadcastReceiver, UITextFieldDelegate, WLStillPictureViewControllerDelegate, WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *imagePlaceholderView;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;

@property (strong, nonatomic) WLProfileEditSession *editSession;

@end

@implementation WLChangeProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.editSession = [[WLProfileEditSession alloc] initWithUser:[WLUser currentUser]];
    self.imagePlaceholderView.layer.cornerRadius = self.imagePlaceholderView.width/2;
    [self updateEmailConfirmationView];
    [[WLUser notifier] addReceiver:self];
}

- (void)updateEmailConfirmationView {
    self.emailConfirmationView.hidden = ![WLAuthorization currentAuthorization].unconfirmed_email.nonempty;
}

- (void)setupEditableUserInterface {
    WLUser *user = [WLUser currentUser];
    self.nameTextField.text = user.name;
    self.imageView.url = user.picture.large;
    if (!self.imageView.url.nonempty) {
        self.imageView.image = [UIImage imageNamed:@"default-large-avatar"];
    }
    self.emailTextField.text = [WLAuthorization priorityEmail];
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

- (IBAction)nameTextFieldChanged:(UITextField *)sender {
    self.editSession.name = self.nameTextField.text;
}

- (IBAction)emailTextFieldChanged:(UITextField *)sender {
    self.editSession.email = self.emailTextField.text;
}

- (IBAction)resendEmailConfirmation:(UIButton*)sender {
    sender.userInteractionEnabled = NO;
    [[WLResendConfirmationRequest request] send:^(id object) {
        WLToastAppearance* appearance = [WLToastAppearance appearance];
        appearance.shouldShowIcon = NO;
        appearance.contentMode = UIViewContentModeCenter;
        [WLToast showWithMessage:@"Confirmation resend. Please, check you e-mail." appearance:appearance];
        sender.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        sender.userInteractionEnabled = YES;
    }];
}

#pragma mark - override base method

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    NSString* email = self.editSession.email;
    if (![email isValidEmail]) {
        if (failure) failure([NSError errorWithDescription:@"Your email isn't correct."]);
    } else if (!self.editSession.name.nonempty) {
        if (failure) failure([NSError errorWithDescription:@"Name connot be blank."]);
    } else {
        if (success) success(nil);
    }
}

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    NSString* email = self.editSession.email;
    if (self.editSession.hasChangedEmail &&
        ![[WLAuthorization currentAuthorization].email isEqualToString:email]) {
        [WLSession setConfirmationDate:nil];
    }
    WLUpdateUserRequest *userRequest = [WLUpdateUserRequest request:[WLUser currentUser]];
    userRequest.email = email;
    [userRequest send:success failure:failure];
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    WLPicture *picture = [pictures lastObject];
    self.imageView.url = picture.large;
    self.editSession.url = picture.large;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier userUpdated:(WLUser *)user {
    [self updateEmailConfirmationView];
}

@end
