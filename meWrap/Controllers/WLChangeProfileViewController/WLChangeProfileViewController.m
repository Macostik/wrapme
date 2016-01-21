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
#import "WLTextView.h"

@interface WLChangeProfileViewController () <KeyboardNotifying, UITextFieldDelegate, WLStillPictureViewControllerDelegate, EntryNotifying, FontPresetting>

@property (weak, nonatomic) IBOutlet ImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *imagePlaceholderView;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;
@property (weak, nonatomic) IBOutlet WLTextView *verificationEmailTextView;
@property (weak, nonatomic) IBOutlet UIButton *resendButton;

@property (strong, nonatomic) ProfileEditSession *editSession;

@end

@implementation WLChangeProfileViewController

@dynamic editSession;

+ (NSAttributedString *)verificationSuggestion {
    return [self verificationSuggestion:[[Authorization currentAuthorization] unconfirmed_email]];
}

+ (NSAttributedString *)verificationSuggestion:(NSString*)email {
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
    self.editSession = [[ProfileEditSession alloc] initWithUser:[User currentUser]];
    self.imagePlaceholderView.layer.cornerRadius = self.imagePlaceholderView.width/2;
    self.verificationEmailTextView.textContainerInset = UIEdgeInsetsZero;
    self.verificationEmailTextView.textContainer.lineFragmentPadding = 0;
    [self updateEmailConfirmationView];
    [[User notifier] addReceiver:self];
    [[FontPresetter defaultPresetter] addReceiver:self];
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
    NSString *unconfirmed_email = [Authorization currentAuthorization].unconfirmed_email;
    if (unconfirmed_email.nonempty) {
        self.verificationEmailTextView.attributedText = [WLChangeProfileViewController verificationSuggestion:unconfirmed_email];
    }
    self.emailConfirmationView.hidden = !unconfirmed_email.nonempty;
}

- (void)setupEditableUserInterface {
    User *user = [User currentUser];
    self.nameTextField.text = user.name;
    self.imageView.url = user.avatar.large;
    self.emailTextField.text = [[Authorization currentAuthorization] priorityEmail];
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

- (IBAction)nameTextFieldChanged:(UITextField *)sender {
    self.editSession.nameSession.changedValue = self.nameTextField.text;
}

- (IBAction)emailTextFieldChanged:(UITextField *)sender {
    self.editSession.emailSession.changedValue = self.emailTextField.text;
}

- (IBAction)resendEmailConfirmation:(UIButton*)sender {
    sender.userInteractionEnabled = NO;
    [[APIRequest resendConfirmation:nil] send:^(id object) {
        [Toast show:@"confirmation_resend".ls];
        sender.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        sender.userInteractionEnabled = YES;
    }];
}

#pragma mark - override base method

- (void)validate:(ObjectBlock)success failure:(FailureBlock)failure {
    if (!self.editSession.emailSession.hasValidChanges) {
        if (failure) failure([[NSError alloc] initWithMessage:@"incorrect_email".ls]);
    } else if (!self.editSession.nameSession.hasValidChanges) {
        if (failure) failure([[NSError alloc] initWithMessage:@"name_cannot_be_blank".ls]);
    } else {
        if (success) success(nil);
    }
}

- (void)apply:(ObjectBlock)success failure:(FailureBlock)failure {
    NSString* email = (NSString*)self.editSession.emailSession.changedValue;
    if (self.editSession.emailSession.hasChanges && ![[Authorization currentAuthorization].email isEqualToString:email]) {
        [[NSUserDefaults standardUserDefaults] setConfirmationDate:nil];
    }
    [[APIRequest updateUser:[User currentUser] email:email] send:success failure:failure];
}

- (void)didCompleteDoneAction {
    self.editSession = [[ProfileEditSession alloc] initWithUser:[User currentUser]];
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
    self.editSession.avatarSession.changedValue = picture.large;
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - EntryNotifying

- (BOOL)notifier:(OrderedNotifier *)notifier shouldNotifyBeforeReceiver:(id)receiver {
    return NO;
}

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Entry *)entry event:(enum EntryUpdateEvent)event {
    [self updateEmailConfirmationView];
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(FontPresetter *)presetter {
      self.verificationEmailTextView.attributedText = [WLChangeProfileViewController verificationSuggestion];
}

@end
