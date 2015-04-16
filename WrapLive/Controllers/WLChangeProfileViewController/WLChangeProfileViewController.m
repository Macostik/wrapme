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
#import "WLNavigationHelper.h"
#import "WLKeyboard.h"
#import "WLInputAccessoryView.h"
#import "WLToast.h"
#import "WLWelcomeViewController.h"
#import "UIButton+Additions.h"
#import "WLProfileEditSession.h"
#import "UIView+AnimationHelper.h"
#import "WLTextView.h"
#import "WLFontPresetter.h"

@interface WLChangeProfileViewController () <WLKeyboardBroadcastReceiver, UITextFieldDelegate, WLStillPictureViewControllerDelegate, WLEntryNotifyReceiver, WLFontPresetterReceiver, WLBroadcastReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *imagePlaceholderView;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;
@property (weak, nonatomic) IBOutlet WLTextView *verificationEmailTextView;
@property (weak, nonatomic) IBOutlet UIButton *resendButton;

@property (strong, nonatomic) WLProfileEditSession *editSession;

@end

@implementation WLChangeProfileViewController

@dynamic editSession;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.imageView setImageName:@"default-large-avatar" forState:WLImageViewStateEmpty];
    [self.imageView setImageName:@"default-large-avatar" forState:WLImageViewStateFailed];
    self.editSession = [[WLProfileEditSession alloc] initWithUser:[WLUser currentUser]];
    self.imagePlaceholderView.layer.cornerRadius = self.imagePlaceholderView.width/2;
    self.verificationEmailTextView.textContainerInset = UIEdgeInsetsZero;
    self.verificationEmailTextView.textContainer.lineFragmentPadding = 0;
    [self updateEmailConfirmationView];
    [[WLUser notifier] addReceiver:self];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (void)updateEmailConfirmationView {
    UIBezierPath *exlusionPath = [UIBezierPath bezierPathWithRect:[self.emailConfirmationView convertRect:self.resendButton.frame
                                                                                                   toView:self.verificationEmailTextView]];
    self.verificationEmailTextView.textContainer.exclusionPaths = @[exlusionPath];
    self.verificationEmailTextView.attributedText = [WLAuthorization attributedVerificationSuggestion];
    self.emailConfirmationView.hidden = ![WLAuthorization currentAuthorization].unconfirmed_email.nonempty;
}

- (void)setupEditableUserInterface {
    WLUser *user = [WLUser currentUser];
    self.nameTextField.text = user.name;
    self.imageView.url = user.picture.large;
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
        [WLToast showWithMessage:WLLS(@"Confirmation resend. Please, check you e-mail.") appearance:appearance];
        sender.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        sender.userInteractionEnabled = YES;
    }];
}

#pragma mark - override base method

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    NSString* email = self.editSession.email;
    if (![email isValidEmail]) {
        if (failure) failure([NSError errorWithDescription:WLLS(@"Your email isn't correct.")]);
    } else if (!self.editSession.name.nonempty) {
        if (failure) failure([NSError errorWithDescription:WLLS(@"Name connot be blank.")]);
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

- (void)didCompleteDoneAction {
    self.editSession = [[WLProfileEditSession alloc] initWithUser:[WLUser currentUser]];
    [self editSession:self.editSession hasChanges:NO];
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

- (WLStillPictureMode)stillPictureViewControllerMode:(WLStillPictureViewController *)controller {
    return WLStillPictureModeSquare;
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier userUpdated:(WLUser *)user {
    [self updateEmailConfirmationView];
}

#pragma mark -  WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
      self.verificationEmailTextView.attributedText = [WLAuthorization attributedVerificationSuggestion];
}

#pragma mark - WLBroadcastReceiver

- (NSNumber *)peferedOrderEntry:(WLBroadcaster *)broadcaster {
    return @(2);
}

@end
