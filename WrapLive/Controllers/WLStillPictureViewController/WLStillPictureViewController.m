//
//  WLStillPictureViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 30.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "ALAssetsLibrary+Additions.h"
#import "ALAssetsLibrary+Additions.h"
#import "AsynchronousOperation.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIImage+Resize.h"
#import "UIView+AnimationHelper.h"
#import "UIView+Shorthand.h"
#import "WLAssetsGroupViewController.h"
#import "WLEntryManager.h"
#import "WLImageFetcher.h"
#import "WLNavigation.h"
#import "WLStillPictureViewController.h"
#import "WLWrap.h"
#import <AviarySDK/AviarySDK.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLPickerViewController.h"
#import "WLCreateWrapViewController.h"
#import "WLWrapViewController.h"
#import "WLCameraViewController.h"
#import "UIImage+Drawing.h"
#import "WLEntryNotifier.h"
#import "WLHintView.h"
#import "WLWrapView.h"
#import "WLUploadPhotoViewController.h"
#import "WLNavigationAnimator.h"

@interface WLStillPictureViewController () <WLCameraViewControllerDelegate, AFPhotoEditorControllerDelegate, UINavigationControllerDelegate, WLEntryNotifyReceiver, WLAssetsViewControllerDelegate>

@property (weak, nonatomic) UINavigationController* cameraNavigationController;
@property (weak, nonatomic) AFPhotoEditorController* aviaryController;

@property (strong, nonatomic) WLImageBlock editBlock;

@property (weak, nonatomic) WLCameraViewController *cameraViewController;

@end

@implementation WLStillPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cameraNavigationController = [self.childViewControllers lastObject];
    self.cameraNavigationController.delegate = self;
    
    if ([self.delegate respondsToSelector:@selector(stillPictureViewControllerMode:)]) {
        self.mode = [self.delegate stillPictureViewControllerMode:self];
    }
    
    WLCameraViewController* cameraViewController = [self.cameraNavigationController.viewControllers lastObject];
    cameraViewController.delegate = self;
    cameraViewController.defaultPosition = self.defaultPosition;
    cameraViewController.wrap = self.wrap;
    self.cameraViewController = cameraViewController;
    
    if (self.startFromGallery) {
        [self openGallery:YES animated:NO];
    }
    
    if (self.mode == WLStillPictureModeDefault) {
        [[WLWrap notifier] addReceiver:self];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (NSUInteger)supportedInterfaceOrientations {
    return [self.cameraNavigationController.topViewController supportedInterfaceOrientations];
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

- (void)setWrap:(WLWrap *)wrap {
    [super setWrap:wrap];
    for (WLStillPictureBaseViewController *controller in self.cameraNavigationController.viewControllers) {
        if ([controller respondsToSelector:@selector(setWrap:)]) {
            controller.wrap = wrap;
        }
    }
}

- (void)showHintView {
    if (!self.wrap) return;
    WLStillPictureBaseViewController *controller = (id)self.cameraNavigationController.topViewController;
    if ([controller isKindOfClass:[WLStillPictureBaseViewController class]]) {
        CGPoint wrapNameCenter = [self.view convertPoint:controller.wrapView.nameLabel.center fromView:controller.wrapView];
        [WLHintView showWrapPickerHintViewInView:[UIWindow mainWindow] withFocusPoint:CGPointMake(74, wrapNameCenter.y)];
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:completion];
    [self showHintView];
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

- (void)cropAsset:(ALAsset*)asset completion:(void (^)(UIImage *croppedImage))completion {
    ALAssetRepresentation* r = asset.defaultRepresentation;
    UIImage* image = [UIImage imageWithCGImage:r.fullResolutionImage scale:r.scale orientation:(UIImageOrientation)r.orientation];
    [self cropImage:image completion:completion];
}

- (AFPhotoEditorController*)editControllerWithImage:(UIImage*)image {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        [AFPhotoEditorController setAPIKey:@"a44aeda8d37b98e1" secret:@"94599065e4e4ee36"];
        [AFPhotoEditorController setPremiumAddOns:AFPhotoEditorPremiumAddOnWhiteLabel];
		[AFPhotoEditorCustomization setLeftNavigationBarButtonTitle:@"Cancel"];
        [AFPhotoEditorCustomization setToolOrder:@[kAFEnhance, kAFEffects, kAFFrames, kAFStickers, kAFFocus,
                                                   kAFOrientation, kAFCrop, kAFDraw, kAFText, kAFBlemish, kAFMeme]];
	});
    if (self.mode == WLStillPictureModeDefault) {
        [AFPhotoEditorCustomization setRightNavigationBarButtonTitle:@"Send"];
    } else {
        [AFPhotoEditorCustomization setRightNavigationBarButtonTitle:@"Save"];
    }
	AFPhotoEditorController* aviaryController = [[AFPhotoEditorController alloc] initWithImage:image];
	aviaryController.delegate = self;
	return aviaryController;
}

- (void)handleImage:(UIImage*)image save:(BOOL)save metadata:(NSMutableDictionary *)metadata {
    __weak typeof(self)weakSelf = self;
    WLImageBlock finishBlock = ^ (UIImage *resultImage) {
        if (save) [resultImage save:metadata];
        if ([weakSelf.delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithPictures:)]) {
            weakSelf.view.userInteractionEnabled = NO;
            [WLPicture picture:resultImage mode:weakSelf.mode completion:^(id object) {
                [weakSelf.delegate stillPictureViewController:weakSelf didFinishWithPictures:@[object]];
                weakSelf.view.userInteractionEnabled = YES;
            }];
        }
    };
    
    [self editImage:image completion:finishBlock];
}

- (void)editImage:(UIImage*)image completion:(WLImageBlock)completion {
    WLUploadPhotoViewController *controller = [WLUploadPhotoViewController instantiate:self.storyboard];
    controller.wrap = self.wrap;
    controller.mode = self.mode;
    controller.image = image;
    controller.completionBlock = completion;
    [self.cameraNavigationController pushViewController:controller animated:YES];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image metadata:(NSMutableDictionary *)metadata {
	self.view.userInteractionEnabled = NO;
	__weak typeof(self)weakSelf = self;
	[self cropImage:image completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage save:YES metadata:metadata];
		weakSelf.view.userInteractionEnabled = YES;
	}];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
    if (self.delegate) {
        [self.delegate stillPictureViewControllerDidCancel:self];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)cameraViewControllerDidSelectGallery:(WLCameraViewController *)controller {
    [self openGallery:NO animated:YES];
}

- (void)openGallery:(BOOL)openCameraRoll animated:(BOOL)animated {
    WLAssetsGroupViewController* gallery = [WLAssetsGroupViewController instantiate:self.storyboard];
    gallery.mode = self.mode;
    gallery.openCameraRoll = openCameraRoll;
    gallery.wrap = self.wrap;
    gallery.delegate = self;
    [self.cameraNavigationController pushViewController:gallery animated:animated];
}

- (void)handleAsset:(ALAsset*)asset {
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [self cropAsset:asset completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage save:NO metadata:nil];
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
        [queue addAsynchronousOperationWithBlock:^(AsynchronousOperation *operation) {
            [weakSelf cropAsset:asset completion:^(UIImage *croppedImage) {
                [WLPicture picture:croppedImage mode:weakSelf.mode completion:^(id object) {
                    [pictures addObject:object];
                    [operation finish:^{
                        run_in_main_queue(^{
                            weakSelf.view.userInteractionEnabled = YES;
                            if ([weakSelf.delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithPictures:)]) {
                                [weakSelf.delegate stillPictureViewController:weakSelf didFinishWithPictures:pictures];
                            }
                        });
                    }];
                }];
            }];
        }];
    }
}

#pragma mark - WLAssetsViewControllerDelegate

- (void)assetsViewController:(id)controller didSelectAssets:(NSArray *)assets {
    if ([assets count] == 1) {
        [self handleAsset:[assets firstObject]];
    } else {
        self.cameraNavigationController.viewControllers = @[self.cameraNavigationController.topViewController];
        [self handleAssets:assets];
    }
}

#pragma mark - AFPhotoEditorControllerDelegate

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image {
    if (self.editBlock) {
        self.editBlock(image);
        self.editBlock = nil;
    }
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor {
    [self.cameraNavigationController popViewControllerAnimated:YES];
}

#pragma mark - PickerViewController action

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier wrapUpdated:(WLWrap *)wrap {
    [self setupWrapView:wrap];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapDeleted:(WLWrap *)wrap {
    self.wrap = [[[WLUser currentUser] sortedWraps] firstObject];
    if (!self.presentedViewController && [self.delegate respondsToSelector:@selector(stillPictureViewController:didSelectWrap:)]) {
        [self.delegate stillPictureViewController:self didSelectWrap:self.wrap];
    }
}

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
    return self.wrap;
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    WLNavigationAnimator *animator = [WLNavigationAnimator new];
    animator.presenting = operation == UINavigationControllerOperationPush;
    return animator;
}

@end
