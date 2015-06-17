//
//  WLOldStillPictureViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLOldStillPictureViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLPickerViewController.h"
#import "WLCreateWrapViewController.h"
#import "WLWrapViewController.h"
#import "WLCameraViewController.h"
#import "WLHintView.h"
#import "WLWrapView.h"
#import "WLUploadPhotoViewController.h"
#import "WLNavigationAnimator.h"
#import "WLHomeViewController.h"
#import "WLSoundPlayer.h"
#import "WLToast.h"
#import "ALAssetsLibrary+Additions.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIView+AnimationHelper.h"
#import "WLAssetsGroupViewController.h"
#import "WLNavigationHelper.h"

@interface WLOldStillPictureViewController () <WLCameraViewControllerDelegate, UINavigationControllerDelegate, WLEntryNotifyReceiver, WLAssetsViewControllerDelegate>

@property (weak, nonatomic) WLCameraViewController *cameraViewController;

@end

@implementation WLOldStillPictureViewController

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
    
    if (self.startFromGallery) {
        [self openGallery:YES animated:NO];
    }
    
    if (self.mode == WLStillPictureModeDefault) {
        [[WLWrap notifier] addReceiver:self];
    }
}

- (UIViewController *)toastAppearanceViewController:(WLToast *)toast {
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __weak typeof(self)weakSelf = self;
    run_after(0.0f, ^{
        if (!weakSelf.presentedViewController) {
            [weakSelf showHintView];
        }
    });
}

- (void)showHintView {
    if (!self.wrap || [WLUser currentUser].wraps.count <= 1) return;
    id <WLStillPictureBaseViewController> controller = (id)self.topViewController;
    if ([controller conformsToProtocol:@protocol(WLStillPictureBaseViewController)] && controller.wrapView) {
        CGPoint wrapNameCenter = [self.view convertPoint:controller.wrapView.nameLabel.center fromView:controller.wrapView];
        [WLHintView showWrapPickerHintViewInView:[UIWindow mainWindow] withFocusPoint:CGPointMake(74, wrapNameCenter.y)];
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:completion];
    [self showHintView];
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

- (void)handleImage:(UIImage*)image metadata:(NSMutableDictionary *)metadata saveToAlbum:(BOOL)saveToAlbum {
    __weak typeof(self)weakSelf = self;
    [self editImage:image completion:^ (UIImage *resultImage, NSString *comment) {
        if (saveToAlbum) [resultImage save:metadata];
        weakSelf.view.userInteractionEnabled = NO;
        [WLEditPicture picture:resultImage mode:weakSelf.mode completion:^(WLEditPicture *picture) {
            picture.comment = comment;
            [weakSelf finishWithPictures:@[picture]];
            weakSelf.view.userInteractionEnabled = YES;
        }];
    }];
}

- (void)editImage:(UIImage*)image completion:(WLUploadPhotoCompletionBlock)completion {
    WLUploadPhotoViewController *controller = [WLUploadPhotoViewController instantiate:self.storyboard];
    controller.wrap = self.wrap;
    controller.mode = self.mode;
    controller.image = image;
    controller.delegate = self;
    controller.completionBlock = completion;
    [self pushViewController:controller animated:NO];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image metadata:(NSMutableDictionary *)metadata {
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [self cropImage:image completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage metadata:metadata saveToAlbum:YES];
        weakSelf.view.userInteractionEnabled = YES;
    }];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
    if (self.delegate) {
        [self.delegate stillPictureViewControllerDidCancel:self];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)cameraViewControllerDidSelectGallery:(WLCameraViewController *)controller {
    [self openGallery:NO animated:NO];
}

- (void)openGallery:(BOOL)openCameraRoll animated:(BOOL)animated {
    WLAssetsGroupViewController* gallery = [WLAssetsGroupViewController instantiate:self.storyboard];
    gallery.mode = self.mode;
    gallery.openCameraRoll = openCameraRoll;
    gallery.wrap = self.wrap;
    gallery.delegate = self;
    [self pushViewController:gallery animated:animated];
}

- (void)handleAsset:(ALAsset*)asset {
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [self cropAsset:asset completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage metadata:nil saveToAlbum:NO];
        weakSelf.view.userInteractionEnabled = YES;
    }];
}

- (void)handleAssets:(NSArray*)assets {
    __weak typeof(self)weakSelf = self;
    self.view.userInteractionEnabled = NO;
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 3;
    NSMutableArray* pictures = [NSMutableArray array];
    for (ALAsset* asset in assets) {
        runQueuedOperation(@"wl_still_picture_queue",3,^(WLOperation *operation) {
            [weakSelf cropAsset:asset completion:^(UIImage *croppedImage) {
                [WLEditPicture picture:croppedImage mode:weakSelf.mode completion:^(WLEditPicture *picture) {
                    [pictures addObject:picture];
                    [operation finish];
                    if (pictures.count == assets.count) {
                        weakSelf.view.userInteractionEnabled = YES;
                        [weakSelf finishWithPictures:pictures];
                    }
                }];
            }];
        });
    }
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

#pragma mark - WLAssetsViewControllerDelegate

- (void)assetsViewController:(id)controller didSelectAssets:(NSArray *)assets {
    if ([assets count] == 1) {
        [self handleAsset:[assets firstObject]];
    } else {
        self.viewControllers = @[self.topViewController];
        [self handleAssets:assets];
    }
}

#pragma mark - PickerViewController action

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
