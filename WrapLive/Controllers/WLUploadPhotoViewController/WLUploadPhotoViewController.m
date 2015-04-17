//
//  WLUploadPhotoViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 2/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUploadPhotoViewController.h"
#import <AviarySDK/AviarySDK.h>
#import "WLNavigationAnimator.h"
#import "WLHintView.h"
#import "WLNavigationHelper.h"
#import "WLIconButton.h"
#import "WLComposeBar.h"
#import "WLAlertView.h"

@interface WLUploadPhotoViewController () <AFPhotoEditorControllerDelegate, WLComposeBarDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet WLIconButton *editButton;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

@property (nonatomic) BOOL edited;

@end

@implementation WLUploadPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imageView.image = self.image;
    
    if (self.mode == WLStillPictureModeSquare) {
        [self.composeBar removeFromSuperview];
    }
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

- (AFPhotoEditorController*)editControllerWithImage:(UIImage*)image {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AFPhotoEditorController setAPIKey:@"a44aeda8d37b98e1" secret:@"94599065e4e4ee36"];
        [AFPhotoEditorController setPremiumAddOns:AFPhotoEditorPremiumAddOnWhiteLabel | AFPhotoEditorPremiumAddOnHiRes];
        [AFPhotoEditorCustomization setToolOrder:@[kAFEnhance, kAFEffects, kAFFrames, kAFStickers, kAFFocus,
                                                   kAFOrientation, kAFCrop, kAFDraw, kAFText, kAFBlemish, kAFMeme]];
    });
    AFPhotoEditorController* aviaryController = [[AFPhotoEditorController alloc] initWithImage:image];
    aviaryController.delegate = self;
    aviaryController.animatorPresentationType = WLNavigationAnimatorPresentationTypeModal;
    return aviaryController;
}

- (IBAction)edit:(id)sender {
    AFPhotoEditorController* aviaryController = [self editControllerWithImage:self.image];
    [self.navigationController pushViewController:aviaryController animated:YES];
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:UIInterfaceOrientationIsPortrait(self.interfaceOrientation)];
}

- (IBAction)done:(id)sender {
    [self.view endEditing:YES];
    if (self.completionBlock) self.completionBlock(self.image, [self.textView.text trim], self.edited);
}

// MARK: - AFPhotoEditorControllerDelegate

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image {
    self.edited = YES;
    self.image = self.imageView.image = image;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor {
    [self.navigationController popViewControllerAnimated:YES];
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
