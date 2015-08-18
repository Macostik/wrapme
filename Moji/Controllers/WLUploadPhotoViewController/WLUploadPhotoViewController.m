//
//  WLUploadPhotoViewController.m
//  moji
//
//  Created by Ravenpod on 2/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUploadPhotoViewController.h"
#import "WLHintView.h"
#import "WLNavigationHelper.h"
#import "WLComposeBar.h"
#import "WLAlertView.h"
#import "WLToast.h"
#import "AdobeUXImageEditorViewController+SharedEditing.h"

@interface WLUploadPhotoViewController () <WLComposeBarDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

@end

@implementation WLUploadPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imageView.image = self.image;
    
    if (self.mode == WLStillPictureModeSquare) {
        [self.composeBar removeFromSuperview];
    }
    
    [UIView performWithoutAnimation:^{
        [UIViewController attemptRotationToDeviceOrientation];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.wrap isFirstCreated]) {
        [WLHintView showEditWrapHintViewInView:[UIWindow mainWindow] withFocusToView:self.editButton];
    }
}

- (void)requestAuthorizationForPresentingEntry:(WLEntry *)entry completion:(WLBooleanBlock)completion {
    if (!completion) return;
    [WLAlertView showWithTitle:WLLS(@"unsaved_photo")
                       message:WLLS(@"leave_screen_on_editing")
                       buttons:@[WLLS(@"cancel"),WLLS(@"continue")]
                    completion:^(NSUInteger index) {
                        completion(index == 1);
                    }];
}

// MARK: - actions

- (IBAction)edit:(id)sender {
    __weak typeof(self)weakSelf = self;
    AFPhotoEditorController* aviaryController = [AdobeUXImageEditorViewController editControllerWithImage:self.image completion:^(UIImage *image, AdobeUXImageEditorViewController *controller) {
        weakSelf.image = weakSelf.imageView.image = image;
        [weakSelf.navigationController popViewControllerAnimated:NO];
    } cancel:^(AdobeUXImageEditorViewController *controller) {
        [weakSelf.navigationController popViewControllerAnimated:NO];
    }];
    [self.navigationController pushViewController:aviaryController animated:NO];
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)done:(id)sender {
    [self.view endEditing:YES];
    if (self.completionBlock) self.completionBlock(self.image, [self.textView.text trim]);
}

// MARK: - rotation and keyboard

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (CGFloat)constantForKeyboardAdjustmentBottomConstraint:(NSLayoutConstraint *)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    return ((keyboardHeight - self.bottomView.height) - (self.imageView.size.height/4 - self.composeBar.height/2)) * constraint.multiplier;
}

// MARK: - WLComposeBarDelegate

- (void)composeBarDidChangeHeight:(WLComposeBar *)composeBar {
    [self keyboardWillShow:[WLKeyboard keyboard]];
}

- (void)composeBarDidBeginEditing:(WLComposeBar *)composeBar {
    [composeBar setDoneButtonHidden:!composeBar.text.nonempty animated:YES];
}

- (void)composeBarDidEndEditing:(WLComposeBar *)composeBar {
    [composeBar setDoneButtonHidden:YES animated:YES];
}

@end
