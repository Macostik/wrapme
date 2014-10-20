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
#import "UIView+AnimationHelper.h"

@interface WLChangeProfileViewController () <WLKeyboardBroadcastReceiver>

@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) WLUser * user;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;

@property (strong, nonatomic) WLProfileEditSession *editSession;


@end

@implementation WLChangeProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.user = [WLUser currentUser];
    self.editSession = [[WLProfileEditSession alloc] initWithUser:self.user];
    self.imagePlaceholderView.layer.cornerRadius = self.imagePlaceholderView.width/2;
	self.stillPictureCameraPosition = AVCaptureDevicePositionFront;
	self.stillPictureMode = WLCameraModeAvatar;
    self.notPresentShakeViewController = YES;
    [self defaultUserInfo];
}

- (IBAction)cancelClick:(id)sender {
    [self defaultUserInfo];
    [self isAtObjectSessionChanged];
    [self.view endEditing:YES];
}

- (void)defaultUserInfo {
    self.nameTextField.text = self.user.name;
    self.imageView.url = self.user.picture.large;
    self.emailTextField.text = [WLAuthorization priorityEmail];
    [self.editSession clean];
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

- (IBAction)editChanged:(UITextField *)sender {
    if (sender == self.nameTextField ) {
        self.editSession.name = self.nameTextField.text;
    } else {
        self.editSession.email = self.emailTextField.text;
    }
    [self isAtObjectSessionChanged];
}

#pragma mark - override base method

- (void)willShowKeyboardWithHeight:(NSNumber *)keyboardHeight
                          duration:(NSTimeInterval)duration
                            option:(UIViewAnimationCurve)animationCurve {
    [super willShowKeyboardWithHeight:keyboardHeight duration:duration option:animationCurve];
    __weak typeof(self)weakSelf = self;
    self.topConstraint.constant = -self.imageView.superview.height;
    [UIView performAnimated:YES animation:^{
        [UIView setAnimationCurve:animationCurve];
        [weakSelf.view layoutIfNeeded];
    }];
}

- (void)willHideKeyboardWithDuration:(NSTimeInterval)duration option:(UIViewAnimationCurve)animationCurve {
    [super willHideKeyboardWithDuration:duration option:animationCurve];
    __weak typeof(self)weakSelf = self;
    self.topConstraint.constant = 0;
    [UIView performAnimated:YES animation:^{
        [UIView setAnimationCurve:animationCurve];
        [weakSelf.view layoutIfNeeded];
    }];
}

- (void)updateIfNeeded:(void (^)(void))completion {
	if ([self isAtObjectSessionChanged]) {
        
		if ([self.editSession.email isValidEmail]) {
            if (self.editSession.hasChangedEmail &&
                ![[WLAuthorization currentAuthorization].email isEqualToString:self.editSession.email]) {
                [WLSession setConfirmationDate:nil];
            }
			[super updateIfNeeded:completion];
			__weak typeof(self)weakSelf = self;
            [self.editSession apply];
            WLUpdateUserRequest *userRequest = [WLUpdateUserRequest request:self.user];
            userRequest.email = self.emailTextField.text;
            [userRequest send:^(id object) {
                [weakSelf.spinner stopAnimating];
				[weakSelf unlock];
				completion();
            } failure:^(NSError *error) {
                [weakSelf.editSession reset];
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
