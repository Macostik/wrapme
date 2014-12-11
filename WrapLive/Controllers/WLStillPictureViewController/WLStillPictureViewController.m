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
#import "UIView+QuatzCoreAnimations.h"
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

@interface WLStillPictureViewController () <WLCameraViewControllerDelegate, AFPhotoEditorControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) UINavigationController* cameraNavigationController;
@property (weak, nonatomic) AFPhotoEditorController* aviaryController;

@property (weak, nonatomic) IBOutlet UIView* wrapView;
@property (weak, nonatomic) IBOutlet UILabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet WLImageView *wrapCoverView;

@property (strong, nonatomic) WLImageBlock editBlock;

@property (weak, nonatomic) WLCameraViewController *cameraViewController;

@end

@implementation WLStillPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.wrapCoverView.circled = YES;
    self.cameraNavigationController = [self.childViewControllers lastObject];
    self.cameraNavigationController.delegate = self;
    WLCameraViewController* cameraViewController = [self.cameraNavigationController.viewControllers lastObject];
    cameraViewController.delegate = self;
    cameraViewController.defaultPosition = self.defaultPosition;
    self.cameraViewController = cameraViewController;
    [self setupWrapView:self.wrap];
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    if (self.isViewLoaded) {
        [self setupWrapView:wrap];
    }
}

- (void)setTranslucent:(BOOL)translucent animated:(BOOL)animated {
    UIColor* color = [self.wrapView.backgroundColor colorWithAlphaComponent:translucent ? 0.5f : 1.0f];
    self.wrapView.backgroundColor = color;
    self.wrapView.transform = translucent ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(.0, WLStillPictureCameraBottomViewHeight);
    [self.wrapView fade];
}

- (void)setupWrapView:(WLWrap *)wrap {
    if (wrap) {
        self.wrapView.hidden = NO;
        self.wrapNameLabel.text = wrap.name;
        self.wrapCoverView.url = wrap.picture.small;
        if (!self.wrapCoverView.url.nonempty) {
            self.wrapCoverView.image = [UIImage imageNamed:@"default-small-cover"];
        }
    } else {
        self.wrapView.hidden = YES;
    }
}

- (CGFloat)imageWidthForCurrentMode {
    if (self.mode == WLStillPictureModeDefault) {
        return 1080;
    } else {
        return 480;
    }
}

- (void)cropImage:(UIImage*)image useCameraAspectRatio:(BOOL)useCameraAspectRatio completion:(void (^)(UIImage *croppedImage))completion {
    __weak typeof(self)weakSelf = self;
	run_getting_object(^id{
        UIImage *result = image;
        CGFloat resultWidth = [self imageWidthForCurrentMode];
        if (useCameraAspectRatio) {
            CGSize newSize = CGSizeThatFitsSize(result.size, weakSelf.view.size);
            CGFloat scale = newSize.width / resultWidth;
            newSize = CGSizeMake(resultWidth, newSize.height / scale);
            result = [result resizedImageWithContentModeScaleAspectFill:CGSizeMake(result.size.width / scale, 1)];
            if (result.size.width > result.size.height) {
                result = [result croppedImage:CGRectThatFitsSize(result.size, CGSizeMake(newSize.height, newSize.width))];
            } else {
                result = [result croppedImage:CGRectThatFitsSize(result.size, newSize)];
            }
        } else {
            result = [result resizedImageWithContentModeScaleAspectFill:CGSizeMake(resultWidth, 1)];
        }
        return result;
	}, completion);
}

- (void)cropAsset:(ALAsset*)asset completion:(void (^)(UIImage *croppedImage))completion {
    ALAssetRepresentation* r = asset.defaultRepresentation;
    UIImage* image = [UIImage imageWithCGImage:r.fullResolutionImage scale:r.scale orientation:(UIImageOrientation)r.orientation];
    [self cropImage:image useCameraAspectRatio:(self.mode != WLStillPictureModeDefault) completion:completion];
}

- (AFPhotoEditorController*)editControllerWithImage:(UIImage*)image {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[AFPhotoEditorCustomization setLeftNavigationBarButtonTitle:@"Cancel"];
		[AFPhotoEditorCustomization setRightNavigationBarButtonTitle:@"Save"];
	});
	AFPhotoEditorController* aviaryController = [[AFPhotoEditorController alloc] initWithImage:image];
	aviaryController.delegate = self;
	aviaryController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	return aviaryController;
}

- (void)handleImage:(UIImage*)image save:(BOOL)save metadata:(NSMutableDictionary *)metadata {
    __weak typeof(self)weakSelf = self;
    WLImageBlock finishBlock = ^ (UIImage *resultImage) {
        if (save) [image save:metadata];
        if ([weakSelf.delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithPictures:)]) {
            weakSelf.view.userInteractionEnabled = NO;
            [WLPicture picture:resultImage completion:^(id object) {
                [weakSelf.delegate stillPictureViewController:weakSelf didFinishWithPictures:@[object]];
                weakSelf.view.userInteractionEnabled = YES;
            }];
        }
    };
    
    [self editImage:image completion:finishBlock];
}

- (void)editImage:(UIImage*)image completion:(WLImageBlock)completion {
    AFPhotoEditorController* aviaryController = [self editControllerWithImage:image];
    self.aviaryController = aviaryController;
    [self.cameraNavigationController pushViewController:aviaryController animated:YES];
    self.editBlock = completion;
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image metadata:(NSMutableDictionary *)metadata {
	self.view.userInteractionEnabled = NO;
	__weak typeof(self)weakSelf = self;
	[self cropImage:image useCameraAspectRatio:YES completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage save:YES metadata:metadata];
		weakSelf.view.userInteractionEnabled = YES;
	}];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self.delegate stillPictureViewControllerDidCancel:self];
}

- (void)cameraViewControllerDidSelectGallery:(WLCameraViewController *)controller {
	WLAssetsGroupViewController* gallery = [[WLAssetsGroupViewController alloc] init];
    gallery.mode = self.mode;
	__weak typeof(self)weakSelf = self;
	[gallery setSelectionBlock:^(NSArray *assets) {
        if ([assets count] == 1) {
            [weakSelf handleAsset:[assets firstObject]];
        } else {
            weakSelf.cameraNavigationController.viewControllers = @[weakSelf.cameraNavigationController.topViewController];
            [weakSelf handleAssets:assets];
        }
	}];
    [self setTranslucent:NO animated:YES];
    [weakSelf.cameraNavigationController pushViewController:gallery animated:YES];
    [self.wrapView leftPushWithDuration:.15 delegate:nil];
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
                [WLPicture picture:croppedImage completion:^(id object) {
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

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    self.wrapView.hidden = YES;
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if (self.wrap) {
        self.wrapView.hidden = viewController == self.aviaryController;
        viewController.hidesBottomBarWhenPushed = YES;
        if (viewController == self.cameraViewController) {
            [self setTranslucent:YES animated:YES];
        }
    }
}

#pragma mark - PickerViewController action

- (IBAction)chooseWrap:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(stillPictureViewController:didSelectWrap:)]) {
        [self.delegate stillPictureViewController:self didSelectWrap:self.wrap];
    }
}

@end
