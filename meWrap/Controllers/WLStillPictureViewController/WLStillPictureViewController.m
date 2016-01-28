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
#import "WLCameraViewController.h"

@interface WLStillPictureViewController () <WLWrapPickerViewControllerDelegate, EntryNotifying>

@end

@implementation WLStillPictureViewController

@dynamic delegate;

@synthesize wrap = _wrap;

@synthesize wrapView = _wrapView;

@synthesize isAvatar = _isAvatar;

+ (instancetype)stillPhotosViewController:(Wrap*)wrap {
    CaptureMediaViewController *controller = (id)[UIStoryboard camera][@"captureMedia"];
    controller.wrap = wrap;
    controller.isAvatar = NO;
    return controller;
}

+ (instancetype)captureAvatarViewController {
    CaptureAvatarViewController *controller = (id)[UIStoryboard camera][@"captureAvatar"];
    controller.isAvatar = YES;
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WLCameraViewController* cameraViewController = [self.viewControllers lastObject];
    cameraViewController.delegate = self;
    cameraViewController.isAvatar = self.isAvatar;
    cameraViewController.wrap = self.wrap;
    self.cameraViewController = cameraViewController;
    
    if (!self.isAvatar) {
        [[Wrap notifier] addReceiver:self];
        if (self.wrap == nil) {
            [self showWrapPickerWithController:NO];
        }
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
        UINavigationController *navigationController = [UINavigationController main];
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
    return self.isAvatar ? 600 : 1200;
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

- (void)cropAsset:(PHAsset*)asset option:(PHImageRequestOptions *)option completion:(void (^)(UIImage *croppedImage))completion {
    CGFloat scale = 0;
    if (asset.pixelWidth > asset.pixelHeight) {
        scale = asset.pixelHeight / [self imageWidthForCurrentMode];
    } else {
        scale = asset.pixelWidth / [self imageWidthForCurrentMode];
    }
    
    BOOL incorrectPhoto = scale < 0.5 && [[UIDevice currentDevice] systemVersionBefore:@"9"];
    CGSize size = incorrectPhoto ?
    CGSizeMake(asset.pixelWidth * scale, asset.pixelHeight * scale) : CGSizeMake(asset.pixelWidth / scale, asset.pixelHeight / scale);
 
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:size
                                              contentMode:PHImageContentModeAspectFill
                                                  options:option
                                            resultHandler:^(UIImage *image, NSDictionary *info) {
                                                if (image != nil) {
                                                    completion(image);
                                                } else {
                                                    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                                                    options.resizeMode   = PHImageRequestOptionsResizeModeExact;
                                                    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
                                                    [self cropAsset:asset option:options completion:completion];
                                                }
                                            }];
}

- (void)handleImage:(UIImage*)image saveToAlbum:(BOOL)saveToAlbum{
    
}

- (void)finishWithPictures:(NSArray*)pictures {
    
    __weak id <WLStillPictureViewControllerDelegate> delegate = [self getValidDelegate];
    if (!self.isAvatar && [self.createdWraps containsObject:self.wrap]) {
        __weak typeof(self)weakSelf = self;
        WLAddContributorsViewController *addFriends = (id)[UIStoryboard main][@"addFriends"];
        addFriends.wrap = self.wrap;
        addFriends.isWrapCreation = YES;
        [addFriends setCompletionHandler:^(BOOL added) {
            weakSelf.friendsInvited = added;
            if ([delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithPictures:)]) {
                [delegate stillPictureViewController:weakSelf didFinishWithPictures:pictures];
            }
        }];
        [self pushViewController:addFriends animated:NO];
    } else {
        if ([delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithPictures:)]) {
            [delegate stillPictureViewController:self didFinishWithPictures:pictures];
        }
    }
}

// MARK: - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController*)controller didCaptureImage:(UIImage *)image saveToAlbum:(BOOL)saveToAlbum {
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

- (void)wrapPickerViewController:(WLWrapPickerViewController *)controller didCreateWrap:(Wrap *)wrap {
    if (!self.createdWraps) {
        self.createdWraps = [NSMutableArray array];
    }
    [self.createdWraps addObject:wrap];
}

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
    if ([self.createdWraps containsObject:entry]) {
        [self.createdWraps removeObject:entry];
    }
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
