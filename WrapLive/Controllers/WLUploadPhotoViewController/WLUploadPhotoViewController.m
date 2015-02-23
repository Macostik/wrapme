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
#import "WLDeviceOrientationBroadcaster.h"
#import "UIView+AnimationHelper.h"

@interface WLUploadPhotoViewController () <AFPhotoEditorControllerDelegate, WLDeviceOrientationBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation WLUploadPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imageView.image = self.image;
    
    self.textView.hidden = self.mode == WLStillPictureModeSquare;
    
    [[WLDeviceOrientationBroadcaster broadcaster] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyOrientation:[UIDevice currentDevice].orientation animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self applyOrientation:[UIDevice currentDevice].orientation animated:NO];
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
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)done:(id)sender {
    if (self.completionBlock) self.completionBlock(self.image);
}

// MARK: - AFPhotoEditorControllerDelegate

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image {
    self.image = self.imageView.image = image;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor {
    [self.navigationController popViewControllerAnimated:YES];
}

// MARK: - WLDeviceOrientationBroadcastReceiver

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)applyOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated {
    CGAffineTransform transform = self.view.transform;
    if (orientation == UIDeviceOrientationLandscapeLeft) {
        transform = CGAffineTransformMakeRotation(M_PI_2);
    } else if (orientation == UIDeviceOrientationLandscapeRight) {
        transform = CGAffineTransformMakeRotation(-M_PI_2);
    } else if (orientation == UIDeviceOrientationPortrait) {
        transform = CGAffineTransformIdentity;
    } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        transform = CGAffineTransformMakeRotation(M_PI);
    }
    if (!CGAffineTransformEqualToTransform(self.view.transform, transform)) {
        [self.view setTransform:transform animated:animated];
        self.view.frame = self.view.superview.bounds;
    }
}

- (void)broadcaster:(WLDeviceOrientationBroadcaster *)broadcaster didChangeOrientation:(NSNumber *)orientation {
    [self applyOrientation:[orientation integerValue] animated:YES];
}

@end
