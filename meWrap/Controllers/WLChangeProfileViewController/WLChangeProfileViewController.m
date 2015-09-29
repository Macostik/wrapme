//
//  WLChangeProfileViewController.m
//  meWrap
//
//  Created by Ravenpod on 4/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLChangeProfileViewController.h"
#import "WLCameraViewController.h"
#import "WLStillPictureViewController.h"
#import "WLNavigationHelper.h"
#import "WLKeyboard.h"
#import "WLToast.h"
#import "WLWelcomeViewController.h"
#import "UIButton+Additions.h"
#import "WLProfileEditSession.h"
#import "UIView+AnimationHelper.h"
#import "WLTextView.h"
#import "WLFontPresetter.h"
#import "WLEditPicture.h"
#import "WLImageView.h"
#import "WLSession.h"

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
    self.editSession = [[WLProfileEditSession alloc] initWithUser:[WLUser currentUser]];
    self.imagePlaceholderView.layer.cornerRadius = self.imagePlaceholderView.width/2;
    self.verificationEmailTextView.textContainerInset = UIEdgeInsetsZero;
    self.verificationEmailTextView.textContainer.lineFragmentPadding = 0;
    [self updateEmailConfirmationView];
    [[WLUser notifier] addReceiver:self];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIBezierPath *exlusionPath = [UIBezierPath bezierPathWithRect:[self.emailConfirmationView convertRect:CGRectInset(self.resendButton.frame, -5, -5)
                                                                                                   toView:self.verificationEmailTextView]];
    CGRect r = [self.view convertRect:self.imagePlaceholderView.frame toView:self.verificationEmailTextView];
    UIBezierPath *avatarPath = [UIBezierPath bezierPathWithOvalInRect:r];
    self.verificationEmailTextView.textContainer.exclusionPaths = @[exlusionPath, avatarPath];
}

- (void)updateEmailConfirmationView {
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
    [[WLAPIRequest resendConfirmation:nil] send:^(id object) {
        [WLToast showWithMessage:WLLS(@"confirmation_resend")];
        sender.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        sender.userInteractionEnabled = YES;
    }];
}

#pragma mark - override base method

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    NSString* email = self.editSession.email;
    if (![email isValidEmail]) {
        if (failure) failure([NSError errorWithDescription:WLLS(@"incorrect_email")]);
    } else if (!self.editSession.name.nonempty) {
        if (failure) failure([NSError errorWithDescription:WLLS(@"name_cannot_be_blank")]);
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
    [[WLAPIRequest updateUser:[WLUser currentUser] email:email] send:success failure:failure];
}

- (void)didCompleteDoneAction {
    self.editSession = [[WLProfileEditSession alloc] initWithUser:[WLUser currentUser]];
    [self editSession:self.editSession hasChanges:NO];
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self updateEmailConfirmationView];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    WLPicture *picture = [[pictures lastObject] uploadablePicture:NO];
    self.imageView.url = picture.large;
    self.editSession.url = picture.large;
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (WLStillPictureMode)stillPictureViewControllerMode:(WLStillPictureViewController *)controller {
    return WLStillPictureModeSquare;
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier willUpdateEntry:(WLUser *)user {
    [self updateEmailConfirmationView];
}

#pragma mark -  WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
      self.verificationEmailTextView.attributedText = [WLAuthorization attributedVerificationSuggestion];
}

#pragma mark - WLBroadcastReceiver

- (NSInteger)broadcasterOrderPriority:(WLBroadcaster *)broadcaster {
    return WLBroadcastReceiverOrderPrioritySecondary;
}

@end
