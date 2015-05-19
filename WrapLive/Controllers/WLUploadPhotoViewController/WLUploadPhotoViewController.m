//
//  WLUploadPhotoViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 2/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUploadPhotoViewController.h"
#import "WLNavigationAnimator.h"
#import "WLHintView.h"
#import "WLNavigationHelper.h"
#import "WLIconButton.h"
#import "WLComposeBar.h"
#import "WLAlertView.h"

@interface WLUploadPhotoViewController () <AdobeUXImageEditorViewControllerDelegate, WLComposeBarDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet WLIconButton *editButton;
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
    [WLAlertView showWithTitle:WLLS(@"Unsaved photo")
                       message:WLLS(@"You are editing a photo and it is not saved yet. Are you sure you want to leave this screen?")
                       buttons:@[WLLS(@"Cancel"),WLLS(@"Continue")]
                    completion:^(NSUInteger index) {
                        completion(index == 1);
                    }];
}

// MARK: - actions

- (IBAction)edit:(id)sender {
    AFPhotoEditorController* aviaryController = [AdobeUXImageEditorViewController editControllerWithImage:self.image delegate:self];
    aviaryController.animatorPresentationType = WLNavigationAnimatorPresentationTypeModal;
    [self.navigationController pushViewController:aviaryController animated:NO];
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)done:(id)sender {
    [self.view endEditing:YES];
    if (self.completionBlock) self.completionBlock(self.image, [self.textView.text trim]);
}

// MARK: - AFPhotoEditorControllerDelegate

- (void)photoEditor:(AdobeUXImageEditorViewController *)editor finishedWithImage:(UIImage *)image {
    self.image = self.imageView.image = image;
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor {
    [self.navigationController popViewControllerAnimated:NO];
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



@implementation AdobeUXImageEditorViewController (AviaryController)

+ (AFPhotoEditorController*)editControllerWithImage:(UIImage*)image delegate:(id)delegate {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:@"a7929bf566694d579acb507eae697db1"
                                                                   withClientSecret:@"b6fa1e1c-4f8c-4001-88a9-0251a099f890"];
    });
    AdobeUXImageEditorViewController* aviaryController = [[self alloc] initWithImage:image];
    aviaryController.delegate = delegate;
    return aviaryController;
}

@end
