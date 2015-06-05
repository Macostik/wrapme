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
#import "WLToast.h"

@interface WLUploadPhotoViewController () <WLComposeBarDelegate>

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

+ (void)editImage:(UIImage *)image completion:(WLImageBlock)completion cancel:(WLBlock)cancel {
    AFPhotoEditorController* aviaryController = [AdobeUXImageEditorViewController editControllerWithImage:image completion:^(UIImage *image, AdobeUXImageEditorViewController *controller) {
        if (completion) completion(image);
        [controller.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    } cancel:^(AdobeUXImageEditorViewController *controller) {
        if (cancel) cancel();
        [controller.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }];
    [[UIWindow mainWindow].rootViewController presentViewController:aviaryController animated:NO completion:nil];
}

static WLImageEditingCompletionBlock _completionBlock = nil;
static WLImageEditingCancelBlock _cancelBlock = nil;

+ (AFPhotoEditorController*)editControllerWithImage:(UIImage*)image completion:(WLImageEditingCompletionBlock)completion cancel:(WLImageEditingCancelBlock)cancel {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AdobeImageEditorCustomization setSupportedIpadOrientations:@[@(UIInterfaceOrientationPortrait),@(UIInterfaceOrientationPortraitUpsideDown),@(UIInterfaceOrientationLandscapeLeft),@(UIInterfaceOrientationLandscapeRight)]];
        [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:@"a7929bf566694d579acb507eae697db1"
                                                                   clientSecret:@"b6fa1e1c-4f8c-4001-88a9-0251a099f890" enableSignUp:NO];
    });
    AdobeUXImageEditorViewController* aviaryController = [[self alloc] initWithImage:image];
    aviaryController.delegate = (id)[AdobeUXImageEditorViewController class];
    _completionBlock = completion;
    _cancelBlock = cancel;
    return aviaryController;
}

// MARK: - AdobeUXImageEditorViewControllerDelegate

+ (void)photoEditor:(AdobeUXImageEditorViewController *)editor finishedWithImage:(UIImage *)image {
    if (_completionBlock) _completionBlock(image, editor);
    _completionBlock = nil;
    _cancelBlock = nil;
}

+ (void)photoEditorCanceled:(AdobeUXImageEditorViewController *)editor {
    if (_cancelBlock) _cancelBlock(editor);
    _completionBlock = nil;
    _cancelBlock = nil;
}

@end
