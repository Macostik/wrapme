//
//  WLStillPictureViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 30.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
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

@interface WLStillPictureViewController () <WLWrapPickerViewControllerDelegate, WLEntryNotifyReceiver>

@end

@implementation WLStillPictureViewController

@dynamic delegate;

@synthesize wrap = _wrap;

@synthesize wrapView = _wrapView;

@synthesize mode = _mode;

+ (instancetype)stillPictureViewController {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if (screenSize.width == 320 && screenSize.height == 480) {
        return [self instantiateWithIdentifier:@"WLStillPictureViewController" storyboard:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    } else {
        return [self instantiateWithIdentifier:@"WLNewStillPictureViewController" storyboard:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    }
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showHintView];
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

- (void)openGallery:(BOOL)openCameraRoll animated:(BOOL)animated {
    WLAssetsGroupViewController* gallery = [WLAssetsGroupViewController instantiate:self.storyboard];
    gallery.mode = self.mode;
    gallery.openCameraRoll = openCameraRoll;
    gallery.wrap = self.wrap;
    gallery.delegate = self;
    [self pushViewController:gallery animated:animated];
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

- (void)showHintView {
    if (!self.wrap || [WLUser currentUser].wraps.count <= 1) return;
    
    for (id controller in self.childViewControllers) {
        if ([controller isKindOfClass:[WLWrapPickerViewController class]]) {
            return;
        }
    }
    
    WLStillPictureBaseViewController *controller = [(id)self.viewControllers lastObject];
    if ([controller isKindOfClass:[WLStillPictureBaseViewController class]] && controller.wrapView) {
        CGPoint wrapNameCenter = [self.view convertPoint:controller.wrapView.nameLabel.center fromView:controller.wrapView];
        [WLHintView showWrapPickerHintViewInView:[UIWindow mainWindow] withFocusPoint:CGPointMake(74, wrapNameCenter.y)];
    }
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

- (void)handleImage:(UIImage*)image metadata:(NSMutableDictionary *)metadata saveToAlbum:(BOOL)saveToAlbum {
    
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

- (void)cameraViewController:(WLCameraViewController*)controller didFinishWithImage:(UIImage*)image metadata:(NSMutableDictionary*)metadata {
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [self cropImage:image completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage metadata:metadata saveToAlbum:YES];
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

- (void)cameraViewControllerDidSelectGallery:(WLCameraViewController*)controller {
    [self openGallery:NO animated:NO];
}

// MARK: - WLAssetsViewControllerDelegate

- (void)assetsViewController:(id)controller didSelectAssets:(NSArray*)assets {
    
}

// MARK: - WLWrapPickerViewControllerDelegate

- (void)wrapPickerViewController:(WLWrapPickerViewController *)controller didSelectWrap:(WLWrap *)wrap {
    self.wrap = wrap;
}

- (void)wrapPickerViewControllerDidCancel:(WLWrapPickerViewController *)controller {
    if (self.wrap) {
        [controller hide];
        [self showHintView];
    } else {
        [self.delegate stillPictureViewControllerDidCancel:self];
    }
}

- (void)wrapPickerViewControllerDidFinish:(WLWrapPickerViewController *)controller {
    [controller hide];
    [self showHintView];
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
