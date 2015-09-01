//
//  WLStillPictureViewController.m
//  moji
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
#import "ALAssetsLibrary+Additions.h"
#import "WLSoundPlayer.h"

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

- (CGSize)imageSizeForCurrentMode {
    if (self.mode == WLStillPictureModeDefault) {
        return CGSizeMake(1200, 1600);
    } else {
        return CGSizeMake(600, 800);
    }
}

- (void)cropImage:(UIImage*)image completion:(void (^)(UIImage *croppedImage))completion {
    __weak typeof(self)weakSelf = self;
    run_getting_object(^id{
        CGSize resultSize = [weakSelf imageSizeForCurrentMode];
        CGFloat resultAspectRatio = 0.75;
        UIImage *result = nil;
        if (image.size.width > image.size.height) {
            CGFloat aspectRatio = image.size.height / image.size.width;
            if (aspectRatio == resultAspectRatio) {
                result = [image resizedImageWithContentModeScaleAspectFill:CGSizeMake(1, resultSize.width)];
            } else if (aspectRatio < resultAspectRatio) {
                result = [image resizedImageWithContentModeScaleAspectFill:CGSizeMake(1, resultSize.width)];
                result = [result croppedImage:CGRectThatFitsSize(result.size, CGSizeMake(resultSize.height, resultSize.width))];
            } else {
                result = [image resizedImageWithContentModeScaleAspectFill:CGSizeMake(resultSize.width, 1)];
                result = [result croppedImage:CGRectThatFitsSize(result.size, CGSizeMake(resultSize.height, resultSize.width))];
            }
        } else {
            CGFloat aspectRatio = image.size.width / image.size.height;
            if (aspectRatio == resultAspectRatio) {
                result = [image resizedImageWithContentModeScaleAspectFill:CGSizeMake(resultSize.width, 1)];
            } else if (aspectRatio < resultAspectRatio) {
                result = [image resizedImageWithContentModeScaleAspectFill:CGSizeMake(resultSize.width, 1)];
                result = [result croppedImage:CGRectThatFitsSize(result.size, resultSize)];
            } else {
                result = [image resizedImageWithContentModeScaleAspectFill:CGSizeMake(1, resultSize.width)];
                result = [result croppedImage:CGRectThatFitsSize(result.size, resultSize)];
            }
        }
        return result;
    }, completion);
}

- (void)cropAsset:(ALAsset*)asset completion:(void (^)(UIImage *croppedImage))completion {
    ALAssetRepresentation* r = asset.defaultRepresentation;
    UIImage* image = [UIImage imageWithCGImage:r.fullResolutionImage scale:r.scale orientation:(UIImageOrientation)r.orientation];
    [self cropImage:image completion:completion];
}

- (void)handleImage:(UIImage*)image metadata:(NSMutableDictionary *)metadata saveToAlbum:(BOOL)saveToAlbum{
    
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

- (void)cameraViewController:(WLCameraViewController*)controller didFinishWithImage:(UIImage*)image metadata:(NSMutableDictionary *)metadata saveToAlbum:(BOOL)saveToAlbum {
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [self cropImage:image completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage metadata:metadata saveToAlbum:saveToAlbum];
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
