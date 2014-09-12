//
//  WLChangeProfileViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 4/24/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChangeProfileViewController.h"
#import "WLCameraViewController.h"
#import "WLNavigation.h"
#import "UIImage+Resize.h"
#import "UIView+Shorthand.h"
#import "WLImageFetcher.h"
#import "WLAPIManager.h"
#import "WLKeyboardBroadcaster.h"
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

@interface WLChangeProfileViewController () <WLKeyboardBroadcastReceiver>

@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) WLUser * user;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *mainView;

@property (strong, nonatomic) WLProfileEditSession *editSession;


@end

@implementation WLChangeProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.user = [WLUser currentUser];
    self.editSession = [[WLProfileEditSession alloc] initWithEntry:self.user];
	self.nameTextField.text = self.user.name;
	self.imageView.url = self.user.picture.large;
    self.imagePlaceholderView.layer.cornerRadius = self.imagePlaceholderView.width/2;
	self.emailTextField.text = [[WLAuthorization currentAuthorization] email];
	self.stillPictureCameraPosition = AVCaptureDevicePositionFront;
	self.stillPictureMode = WLCameraModeAvatar;
    self.notPresentShakeViewController = YES;
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
}

- (void)validateDoneButton {
    NSString * email = self.emailTextField.text;
    self.doneButton.active = self.nameTextField.text.nonempty && email.nonempty && email.isValidEmail;
}

#pragma mark - User actions

- (IBAction)changeAccount:(id)sender {
	[WLSession clear];
	[WLWelcomeViewController instantiateAndMakeRootViewControllerAnimated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString* resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	return resultString.length <= WLProfileNameLimit;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == self.nameTextField && ![self.editSession.name isEqualToString:self.nameTextField.text]) {
        self.editSession.name = self.nameTextField.text;
	} else if (![self.editSession.email isEqualToString:self.emailTextField.text]) {
		self.editSession.email = self.emailTextField.text;
	}
	[self isAtObjectSessionChanged];
}

#pragma mark - WLKeyboardBroadcastReceiver

- (void)broadcaster:(WLKeyboardBroadcaster *)broadcaster willShowKeyboardWithHeight:(NSNumber *)keyboardHeight {
	__weak typeof(self)weakSelf = self;
	CGAffineTransform transform = self.mainView.transform;
	self.mainView.transform = CGAffineTransformIdentity;
	CGPoint center = [self.view convertPoint:self.nameTextField.center fromView:self.nameTextField.superview];
	CGFloat translation = center.y - (self.view.height - [keyboardHeight floatValue])/2.0f;
	self.mainView.transform = transform;
	[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		weakSelf.mainView.transform = CGAffineTransformMakeTranslation(0, -translation);
	} completion:^(BOOL finished) {}];
}

- (void)broadcasterWillHideKeyboard:(WLKeyboardBroadcaster *)broadcaster {
	__weak typeof(self)weakSelf = self;
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		weakSelf.mainView.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {}];
}

#pragma mark override base method

- (void)updateIfNeeded:(void (^)(void))completion {
	if ([self isAtObjectSessionChanged]) {
        
		if ([self.editSession.email isValidEmail]) {
			[super updateIfNeeded:completion];
			__weak typeof(self)weakSelf = self;
            [self.editSession apply:self.user];
            WLUpdateUserRequest *userRequest = [WLUpdateUserRequest request:self.user];
            userRequest.email = self.emailTextField.text;
            [userRequest send:^(id object) {
                [weakSelf.spinner stopAnimating];
				[weakSelf unlock];
				completion();
            } failure:^(NSError *error) {
                [weakSelf.editSession reset:weakSelf.user];
				[weakSelf.spinner stopAnimating];
				[weakSelf unlock];
				[error show];
            }];
		} else {
			[WLToast showWithMessage:@"Your email isn't correct."];
		}
		
	} else {
		completion();
	}
}

- (void)saveImage:(UIImage *)image {
	__weak typeof(self)weakSelf = self;
	[[WLImageCache cache] setImage:image completion:^(NSString *path) {
		weakSelf.editSession.url = path;
		[weakSelf isAtObjectSessionChanged];
	}];
}

@end
