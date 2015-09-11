//
//  WLStillPictureViewController.m
//  meWrap
//
//  Created by Ravenpod on 30.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLStillPictureViewController.h"
#import "WLNavigationHelper.h"
#import "WLWrapPickerViewController.h"
#import "WLToast.h"
#import "WLHomeViewController.h"
#import "WLHintView.h"
#import "WLWrapView.h"
#import "WLCameraViewController.h"
#import "WLSoundPlayer.h"

@import Photos;

@interface WLStillPictureViewController () <WLWrapPickerViewControllerDelegate, WLEntryNotifyReceiver>

@end

@implementation WLStillPictureViewController

@dynamic delegate;

@synthesize wrap = _wrap;

@synthesize wrapView = _wrapView;

@synthesize mode = _mode;

+ (instancetype)stillPhotosViewController {
    return [self instantiateWithIdentifier:@"WLStillPhotosViewController" storyboard:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
}

+ (instancetype)stillAvatarViewController {
    return [self instantiateWithIdentifier:@"WLStillAvatarViewController" storyboard:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    id <WLStillPictureViewControllerDelegate> delegate = [self getValidDelegate];
    if ([delegate respondsToSelector:@selector(stillPictureViewControllerMode:)]) {
        self.mode = [delegate stillPictureViewControllerMode:self];
    }
    
    WLCameraViewController* cameraViewController = [self.viewControllers lastObject];
    cameraViewController.delegate = self;
    cameraViewController.mode = self.mode;
    cameraViewController.wrap = self.wrap;
    self.cameraViewController = cameraViewController;
    
    if (self.mode == WLStillPictureModeDefault) {
        [[WLWrap notifier] addReceiver:self];
    }
    
    if (self.wrap == nil && self.mode == WLStillPictureModeDefault) {
        [self showWrapPickerWithController:NO];
    }
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    for (id <WLStillPictureBaseViewController> controller in self.viewControllers) {
        if ([controller conformsToProtocol:@protocol(WLStillPictureBaseViewController)]) {
            controller.wrap = wrap;
        }
    }
}

- (void)setupWrapView:(WLWrap *)wrap {
    
}

- (IBAction)selectWrap:(UIButton *)sender {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(stillPictureViewController:didSelectWrap:)]) {
            [self.delegate stillPictureViewController:self didSelectWrap:self.wrap];
        }
    } else if (self.presentingViewController) {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)stillPictureViewController:(id<WLStillPictureBaseViewController>)controller didSelectWrap:(WLWrap *)wrap {
    [self showWrapPickerWithController:YES];
}

- (void)showWrapPickerWithController:(BOOL)animated {
    [self.view layoutIfNeeded];
    WLWrapPickerViewController *pickerController = [WLWrapPickerViewController instantiate:self.storyboard];
    pickerController.delegate = self;
    pickerController.wrap = self.wrap;
    [pickerController showInViewController:self animated:NO];
}

- (UIViewController *)toastAppearanceViewController:(WLToast *)toast {
    for (UIViewController *controller in self.childViewControllers) {
        if ([controller isKindOfClass:[WLWrapPickerViewController class]]) {
            return controller;
        }
    }
    return [self.topViewController toastAppearanceViewController:toast];
}

- (id<WLStillPictureViewControllerDelegate>)getValidDelegate {
    id delegate = self.delegate;
    if (!delegate) {
        UINavigationController *navigationController = [UINavigationController mainNavigationController];
        WLHomeViewController *homeViewController = [navigationController.viewControllers firstObject];
        if ([homeViewController isKindOfClass:[WLHomeViewController class]]) {
            delegate = self.delegate = homeViewController;
        }
    }
    return delegate;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (void)requestAuthorizationForPresentingEntry:(WLEntry *)entry completion:(WLBooleanBlock)completion {
    [self.topViewController requestAuthorizationForPresentingEntry:entry completion:completion];
}

- (CGFloat)imageWidthForCurrentMode {
    if (self.mode == WLStillPictureModeDefault) {
        return 1200;
    } else {
        return 600;
    }
}

- (void)cropImage:(UIImage*)image completion:(void (^)(UIImage *croppedImage))completion {
    __weak typeof(self)weakSelf = self;
    run_getting_object(^id{
        CGFloat resultWidth = [weakSelf imageWidthForCurrentMode];
        if (image.size.width > image.size.height) {
            return [image resizedImageWithContentModeScaleAspectFill:CGSizeMake(1, resultWidth)];
        } else {
            return [image resizedImageWithContentModeScaleAspectFill:CGSizeMake(resultWidth, 1)];
        }
    }, completion);
}

- (void)cropAsset:(PHAsset*)asset completion:(void (^)(UIImage *croppedImage))completion {
    __weak __typeof(self)weakSelf = self;
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:PHImageManagerMaximumSize
                                              contentMode:PHImageContentModeAspectFill 
                                                  options:nil
                                            resultHandler:^(UIImage *image, NSDictionary *info) {
        [weakSelf cropImage:image completion:completion];
    }];
}

- (void)handleImage:(UIImage*)image saveToAlbum:(BOOL)saveToAlbum{
    
}

- (void)finishWithPictures:(NSArray*)pictures {
    
    if (self.mode == WLStillPictureModeDefault) {
        [WLSoundPlayer playSound:WLSound_s04];
    }
    
    id <WLStillPictureViewControllerDelegate> delegate = [self getValidDelegate];
    if ([delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithPictures:)]) {
        [delegate stillPictureViewController:self didFinishWithPictures:pictures];
    }
}

// MARK: - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController*)controller didFinishWithImage:(UIImage*)image saveToAlbum:(BOOL)saveToAlbum {
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [self cropImage:image completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage saveToAlbum:saveToAlbum];
        weakSelf.view.userInteractionEnabled = YES;
    }];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController*)controller {
    if (self.delegate) {
        [self.delegate stillPictureViewControllerDidCancel:self];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }
}

// MARK: - WLWrapPickerViewControllerDelegate

- (void)wrapPickerViewController:(WLWrapPickerViewController *)controller didSelectWrap:(WLWrap *)wrap {
    self.wrap = wrap;
}

- (void)wrapPickerViewControllerDidCancel:(WLWrapPickerViewController *)controller {
    if (self.wrap) {
        [controller hide];
    } else {
        [self.delegate stillPictureViewControllerDidCancel:self];
    }
}

- (void)wrapPickerViewControllerDidFinish:(WLWrapPickerViewController *)controller {
    [controller hide];
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLWrap *)wrap {
    [self setupWrapView:wrap];
}

- (void)notifier:(WLEntryNotifier *)notifier didDeleteEntry:(WLWrap *)wrap {
    self.wrap = [[[WLUser currentUser] sortedWraps] firstObject];
    id <WLStillPictureViewControllerDelegate> delegate = [self getValidDelegate];
    if (!self.presentedViewController && [delegate respondsToSelector:@selector(stillPictureViewController:didSelectWrap:)]) {
        [delegate stillPictureViewController:self didSelectWrap:self.wrap];
    }
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.wrap == entry;
}

@end
