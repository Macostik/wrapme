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
#import "WLNavigation.h"
#import "UIView+Shorthand.h"
#import "WLIconButton.h"
#import "WLUser+Extended.h"
#import "WLComposeBar.h"

static CGFloat WLHeightCoposeBarConstrain = 132.0;

@interface WLUploadPhotoViewController () <AFPhotoEditorControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet WLIconButton *editButton;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

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
    [WLHintView showEditWrapHintViewInView:[UIWindow mainWindow] withFocusToView:self.editButton];
}

// MARK: - actions

- (AFPhotoEditorController*)editControllerWithImage:(UIImage*)image {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AFPhotoEditorController setAPIKey:@"a44aeda8d37b98e1" secret:@"94599065e4e4ee36"];
        [AFPhotoEditorController setPremiumAddOns:AFPhotoEditorPremiumAddOnWhiteLabel];
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
    if (self.completionBlock) self.completionBlock(self.image, self.textView.text, self.edited);
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

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return self.view.height - WLHeightCoposeBarConstrain - CGRectGetMaxY(self.editButton.frame) - (self.view.height - keyboardHeight)/2;
}

@end
