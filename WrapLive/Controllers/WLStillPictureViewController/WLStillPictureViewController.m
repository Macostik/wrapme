//
//  WLStillPictureViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 30.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLStillPictureViewController.h"
#import "WLNavigation.h"
#import "WLAssetsGroupViewController.h"
#import "ALAssetsLibrary+Additions.h"
#import <AviarySDK/AviarySDK.h>
#import "WLBlocks.h"
#import "UIImage+Resize.h"
#import "WLSupportFunctions.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "NSMutableDictionary+ImageMetadata.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "WLWrap.h"
#import "UIView+Shorthand.h"
#import "WLImageFetcher.h"
#import "UIView+AnimationHelper.h"
#import "WLEntryManager.h"
#import "AsynchronousOperation.h"

@interface WLStillPictureViewController () <WLCameraViewControllerDelegate, AFPhotoEditorControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) UINavigationController* cameraNavigationController;

@property (weak, nonatomic) IBOutlet UIView* wrapView;
@property (weak, nonatomic) IBOutlet UILabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet WLImageView *wrapCoverView;

@property (strong, nonatomic) WLImageBlock editBlock;

@end

@implementation WLStillPictureViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.editable = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cameraViewController = self.mode == WLCameraModeCandy ? [WLCameraViewController instantiateWithIdentifier:@"WLFullSizeCameraViewController"] : [WLCameraViewController instantiate];
    self.cameraViewController.delegate = self;
    self.cameraViewController.mode = self.mode;
    self.cameraViewController.defaultPosition = self.defaultPosition;
    self.cameraViewController.bottomInset = self.wrap ? self.wrapView.height : 0;
    
    if (self.wrap) {
        self.wrapView.hidden = NO;
        self.wrapNameLabel.text = self.wrap.name;
        self.wrapCoverView.url = self.wrap.picture.small;
    } else {
        self.wrapView.hidden = YES;
    }
    
    self.cameraNavigationController.view.frame = self.view.bounds;
    [self.view insertSubview:self.cameraNavigationController.view atIndex:0];
    
	[self.cameraNavigationController setViewControllers:@[self.cameraViewController]];
}

- (void)setTranslucent:(BOOL)translucent animated:(BOOL)animated {
    if (self.wrap) {
        UIColor* color = [self.wrapView.backgroundColor colorWithAlphaComponent:translucent ? 0.5f : 1.0f];
        __weak typeof(self)weakSelf = self;
        [UIView performAnimated:animated animation:^{
            weakSelf.wrapView.backgroundColor = color;
        }];
        
        weakSelf.cameraNavigationController.view.height = weakSelf.view.height - (translucent ? 0 : weakSelf.wrapView.height);
    }
}

- (UINavigationController *)cameraNavigationController {
    if (!_cameraNavigationController) {
        UINavigationController* controller = [[UINavigationController alloc] init];
        controller.navigationBarHidden = YES;
        [self addChildViewController:controller];
        [controller didMoveToParentViewController:self];
        controller.delegate = self;
        _cameraNavigationController = controller;
    }
    return _cameraNavigationController;
}

- (void)setMode:(WLCameraMode)mode {
    _mode = mode;
}

- (void)setDefaultPosition:(AVCaptureDevicePosition)defaultPosition {
    _defaultPosition = defaultPosition;
}

- (CGFloat)imageWidthForCurrentMode {
    WLCameraMode mode = self.mode;
    if (mode == WLCameraModeCandy) {
        return 720;
    } else {
        return 480;
    }
}

- (void)cropImage:(UIImage*)image useCameraAspectRatio:(BOOL)useCameraAspectRatio completion:(void (^)(UIImage *croppedImage))completion {
	CGSize viewSize = self.cameraViewController.viewSize;
	run_getting_object(^id{
        UIImage *result = image;
        CGFloat resultWidth = [self imageWidthForCurrentMode];
        if (useCameraAspectRatio) {
            CGSize newSize = CGSizeThatFitsSize(result.size, viewSize);
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
    [self cropImage:image useCameraAspectRatio:(self.mode != WLCameraModeCandy) completion:completion];
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
    WLCameraMode mode = self.mode;

    __weak typeof(self)weakSelf = self;
    
    WLImageBlock finishBlock = ^ (UIImage *resultImage) {
        
        if (save) [weakSelf saveImage:image metadata:metadata];
        
        if (mode == WLCameraModeCandy) {
            if ([weakSelf.delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithPictures:)]) {
                weakSelf.view.userInteractionEnabled = NO;
                [WLPicture picture:resultImage completion:^(id object) {
                    [weakSelf.delegate stillPictureViewController:weakSelf didFinishWithPictures:@[object]];
                    weakSelf.view.userInteractionEnabled = YES;
                }];
            }
        } else if ([weakSelf.delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithImage:)]) {
            [weakSelf.delegate stillPictureViewController:weakSelf didFinishWithImage:resultImage];
        }
    };
    
    if (self.editable) {
        [self editImage:image completion:finishBlock];
    } else {
        finishBlock(image);
    }
}

- (void)editImage:(UIImage*)image completion:(WLImageBlock)completion {
    [self setTranslucent:NO animated:YES];
	[self.cameraNavigationController pushViewController:[self editControllerWithImage:image] animated:YES];
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

- (void)saveImage:(UIImage*)image metadata:(NSMutableDictionary *)metadata {
	[metadata setImageOrientation:image.imageOrientation];
	run_in_default_queue(^{
		ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
		[library saveImage:image
				   toAlbum:@"wrapLive"
				  metadata:metadata
				completion:^(NSURL *assetURL, NSError *error) { }
				   failure:^(NSError *error) { }];
	});
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
            [weakSelf handleAssets:assets];
        }
	}];
    [self setTranslucent:NO animated:YES];
	[self.cameraNavigationController pushViewController:gallery animated:YES];
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

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.wrap) {
        if (viewController == self.cameraViewController) {
            [self setTranslucent:YES animated:YES];
        }
    }
}

@end
