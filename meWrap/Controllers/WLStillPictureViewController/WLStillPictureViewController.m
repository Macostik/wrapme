//
//  WLStillPictureViewController.m
//  meWrap
//
//  Created by Ravenpod on 30.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLStillPictureViewController.h"
#import "WLWrapPickerViewController.h"
#import "WLHomeViewController.h"
#import "WLHintView.h"
#import "WLCameraViewController.h"

@import Photos;

@interface WLStillPictureViewController () <WLWrapPickerViewControllerDelegate, EntryNotifying>

@end

@implementation WLStillPictureViewController

@dynamic delegate;

@synthesize wrap = _wrap;

@synthesize wrapView = _wrapView;

@synthesize mode = _mode;

+ (instancetype)stillPhotosViewController {
    return (id)[UIStoryboard camera][@"WLStillPhotosViewController"];
}

+ (instancetype)stillAvatarViewController {
    return (id)[UIStoryboard camera][@"WLStillAvatarViewController"];
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
    
    if (self.mode == StillPictureModeDefault) {
        [[Wrap notifier] addReceiver:self];
    }
    
    if (self.wrap == nil && self.mode == StillPictureModeDefault) {
        [self showWrapPickerWithController:NO];
    }
}

- (void)setWrap:(Wrap *)wrap {
    _wrap = wrap;
    for (id <WLStillPictureBaseViewController> controller in self.viewControllers) {
        if ([controller conformsToProtocol:@protocol(WLStillPictureBaseViewController)]) {
            controller.wrap = wrap;
        }
    }
}

- (void)setupWrapView:(Wrap *)wrap {
    
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

- (void)stillPictureViewController:(id<WLStillPictureBaseViewController>)controller didSelectWrap:(Wrap *)wrap {
    [self showWrapPickerWithController:YES];
}

- (void)showWrapPickerWithController:(BOOL)animated {
    [self.view layoutIfNeeded];
    WLWrapPickerViewController *pickerController = (id)self.storyboard[@"WLWrapPickerViewController"];
    pickerController.delegate = self;
    pickerController.wrap = self.wrap;
    [pickerController showInViewController:self animated:NO];
}

- (UIViewController *)toastAppearanceViewController:(Toast *)toast {
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
            delegate = homeViewController;
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

- (void)requestAuthorizationForPresentingEntry:(Entry *)entry completion:(BooleanBlock)completion {
    [self.topViewController requestAuthorizationForPresentingEntry:entry completion:completion];
}

- (CGFloat)imageWidthForCurrentMode {
    if (self.mode == StillPictureModeDefault) {
        return 1200;
    } else {
        return 600;
    }
}

- (void)cropImage:(UIImage*)image completion:(void (^)(UIImage *croppedImage))completion {
    __weak typeof(self)weakSelf = self;
    [[Dispatch defaultQueue] fetch:^id _Nullable{
        CGFloat resultWidth = [weakSelf imageWidthForCurrentMode];
        UIImage *resultImage = nil;
        CGSize fitSize = CGSizeThatFitsSize(image.size, weakSelf.view.size);
        if (image.size.width > image.size.height) {
            CGFloat scale = image.size.height / fitSize.height;
            resultImage = [image resize:CGSizeMake(1, resultWidth * scale) aspectFill:YES];
        } else {
            CGFloat scale = image.size.width / fitSize.width;
            resultImage = [image resize:CGSizeMake(resultWidth * scale, 1) aspectFill:YES];
        }
        CGRect cropRect = CGRectThatFitsSize(resultImage.size, weakSelf.view.size);
        resultImage = [resultImage crop:cropRect];
        return resultImage;
    } completion:completion];
}

- (void)cropAsset:(PHAsset*)asset completion:(void (^)(UIImage *croppedImage))completion {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode   = PHImageRequestOptionsResizeModeExact;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
  
    CGFloat scale = 0;
    if (asset.pixelWidth > asset.pixelHeight) {
        scale = asset.pixelHeight / [self imageWidthForCurrentMode];
    } else {
        scale = asset.pixelWidth / [self imageWidthForCurrentMode];
    }
    CGSize size = scale < 0.5 && [[UIDevice currentDevice] systemVersionBefore:@"9"] ?
    CGSizeMake(asset.pixelWidth * scale, asset.pixelHeight * scale) : CGSizeMake(asset.pixelWidth / scale, asset.pixelHeight / scale);
 
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:size
                                              contentMode:PHImageContentModeAspectFill
                                                  options:options
                                            resultHandler:^(UIImage *image, NSDictionary *info) {
                                                    completion(image);
                                            }];
}

- (void)handleImage:(UIImage*)image saveToAlbum:(BOOL)saveToAlbum{
    
}

- (void)finishWithPictures:(NSArray*)pictures {
    
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

- (void)wrapPickerViewController:(WLWrapPickerViewController *)controller didSelectWrap:(Wrap *)wrap {
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

// MARK: - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Wrap *)wrap event:(enum EntryUpdateEvent)event {
    [self setupWrapView:wrap];
}

- (void)notifier:(EntryNotifier *)notifier willDeleteEntry:(Entry *)entry {
    self.wrap = [[[User currentUser] sortedWraps] firstObject];
    id <WLStillPictureViewControllerDelegate> delegate = [self getValidDelegate];
    if (!self.presentedViewController && [delegate respondsToSelector:@selector(stillPictureViewController:didSelectWrap:)]) {
        [delegate stillPictureViewController:self didSelectWrap:self.wrap];
    }
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.wrap == entry;
}

@end
