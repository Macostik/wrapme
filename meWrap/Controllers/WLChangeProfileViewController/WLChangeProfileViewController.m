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
#import "WLProfileEditSession.h"
#import "WLTextView.h"
#import "WLFontPresetter.h"
#import "WLImageView.h"

@interface WLChangeProfileViewController () <WLKeyboardBroadcastReceiver, UITextFieldDelegate, WLStillPictureViewControllerDelegate, EntryNotifying, WLFontPresetterReceiver, WLBroadcastReceiver>

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

+ (NSAttributedString *)attributedVerificationSuggestion {
    NSString *email = [[Authorization currentAuthorization] unconfirmed_email];
    NSMutableAttributedString *emailVerificationString = [[NSMutableAttributedString alloc] initWithString:
                                                          [[NSString alloc] initWithFormat:@"formatted_verification_email_text".ls, email]];
    NSRange fullRange = NSMakeRange(0, emailVerificationString.length);
    NSRange bitRange = [emailVerificationString.string rangeOfString:email];
    [emailVerificationString setAttributes:@{NSFontAttributeName:[UIFont lightFontXSmall]}
                                     range:fullRange];
    [emailVerificationString setAttributes:@{NSFontAttributeName:[UIFont fontXSmall]}
                                     range:bitRange];
    return emailVerificationString;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.editSession = [[WLProfileEditSession alloc] initWithUser:[User currentUser]];
    self.imagePlaceholderView.layer.cornerRadius = self.imagePlaceholderView.width/2;
    self.verificationEmailTextView.textContainerInset = UIEdgeInsetsZero;
    self.verificationEmailTextView.textContainer.lineFragmentPadding = 0;
    [self updateEmailConfirmationView];
    [[User notifier] addReceiver:self];
    [[WLFontPresetter defaultPresetter] addReceiver:self];
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
    self.verificationEmailTextView.attributedText = [WLChangeProfileViewController attributedVerificationSuggestion];
    self.emailConfirmationView.hidden = ![Authorization currentAuthorization].unconfirmed_email.nonempty;
}

- (void)setupEditableUserInterface {
    User *user = [User currentUser];
    self.nameTextField.text = user.name;
    self.imageView.url = user.picture.large;
    self.emailTextField.text = [[Authorization currentAuthorization] priorityEmail];
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
        [WLToast showWithMessage:@"confirmation_resend".ls];
        sender.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        sender.userInteractionEnabled = YES;
    }];
}

#pragma mark - override base method

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    NSString* email = self.editSession.email;
    if (![email isValidEmail]) {
        if (failure) failure([NSError errorWithDescription:@"incorrect_email".ls]);
    } else if (!self.editSession.name.nonempty) {
        if (failure) failure([NSError errorWithDescription:@"name_cannot_be_blank".ls]);
    } else {
        if (success) success(nil);
    }
}

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    NSString* email = self.editSession.email;
    if (self.editSession.hasChangedEmail &&
        ![[Authorization currentAuthorization].email isEqualToString:email]) {
        [[NSUserDefaults standardUserDefaults] setConfirmationDate:nil];
    }
    [[WLAPIRequest updateUser:[User currentUser] email:email] send:success failure:failure];
}

- (void)didCompleteDoneAction {
    self.editSession = [[WLProfileEditSession alloc] initWithUser:[User currentUser]];
    [self editSession:self.editSession hasChanges:NO];
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self updateEmailConfirmationView];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    Asset *picture = [[pictures lastObject] uploadablePicture:NO];
    self.imageView.url = picture.large;
    self.editSession.url = picture.large;
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (WLStillPictureMode)stillPictureViewControllerMode:(WLStillPictureViewController *)controller {
    return WLStillPictureModeSquare;
}

#pragma mark - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier willUpdateEntry:(User *)user {
    [self updateEmailConfirmationView];
}

#pragma mark -  WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
      self.verificationEmailTextView.attributedText = [WLChangeProfileViewController attributedVerificationSuggestion];
}

#pragma mark - WLBroadcastReceiver

- (NSInteger)broadcasterOrderPriority:(WLBroadcaster *)broadcaster {
    return WLBroadcastReceiverOrderPrioritySecondary;
}

@end
