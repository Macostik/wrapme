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
@property (weak, nonatomic) IBOutlet UIImageView *wrapCoverView;

@end

@implementation WLStillPictureViewController

@synthesize mode = _mode;

- (void)viewDidLoad {
    [super viewDidLoad];
	self.cameraViewController.wrap = self.wrap;
    
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

- (WLCameraViewController *)cameraViewController {
	if (!_cameraViewController) {
		_cameraViewController = [WLCameraViewController instantiate];
		_cameraViewController.delegate = self;
	}
	return _cameraViewController;
}

- (WLCameraMode)mode {
	return self.cameraViewController.mode;
}

- (void)setMode:(WLCameraMode)mode {
	self.cameraViewController.mode = mode;
}

- (AVCaptureDevicePosition)defaultPosition {
	return self.cameraViewController.defaultPosition;
}

- (void)setDefaultPosition:(AVCaptureDevicePosition)defaultPosition {
	self.cameraViewController.defaultPosition = defaultPosition;
}

- (CGFloat)imageWidthForCurrentMode {
    WLCameraMode mode = self.mode;
    if (mode == WLCameraModeCandy) {
        return 720;
    } else {
        return 480;
    }
}

- (void)cropImage:(UIImage*)image completion:(void (^)(UIImage *croppedImage))completion {
	__weak typeof(self)weakSelf = self;
	CGSize viewSize = self.cameraViewController.viewSize;
	run_getting_object(^id{
		CGFloat width = [weakSelf imageWidthForCurrentMode];
        UIImage *result = [image resizedImageWithContentModeScaleAspectFill:CGSizeMake(width, width)];
		if (weakSelf.mode != WLCameraModeCandy) {
			result = [result croppedImage:CGRectThatFitsSize(result.size, viewSize)];
		}
		return result;
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
		[AFPhotoEditorCustomization setLeftNavigationBarButtonTitle:@"Cancel"];
		[AFPhotoEditorCustomization setRightNavigationBarButtonTitle:@"Save"];
	});
	AFPhotoEditorController* aviaryController = [[AFPhotoEditorController alloc] initWithImage:image];
	aviaryController.delegate = self;
	aviaryController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	return aviaryController;
}

- (void)editImage:(UIImage*)image {
    [self setTranslucent:NO animated:YES];
	[self.cameraNavigationController pushViewController:[self editControllerWithImage:image] animated:YES];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image metadata:(NSMutableDictionary *)metadata {
	self.view.userInteractionEnabled = NO;
	__weak typeof(self)weakSelf = self;
	[self cropImage:image completion:^(UIImage *croppedImage) {
		[weakSelf saveImage:croppedImage metadata:metadata];
		[weakSelf editImage:croppedImage];
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
        [weakSelf editImage:croppedImage];
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
    if (self.mode == WLCameraModeCandy) {
        __weak typeof(self)weakSelf = self;
        [WLPicture picture:image completion:^(id object) {
            if ([weakSelf.delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithPictures:)]) {
                [weakSelf.delegate stillPictureViewController:weakSelf didFinishWithPictures:@[object]];
            }
        }];
    } else {
        [self.delegate stillPictureViewController:self didFinishWithImage:image];
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
