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

@interface WLStillPictureViewController () <WLCameraViewControllerDelegate, AFPhotoEditorControllerDelegate>

@property (weak, nonatomic) UINavigationController* cameraNavigationController;

@property (weak, nonatomic) IBOutlet UIView* wrapView;
@property (weak, nonatomic) IBOutlet UIView *navigationView;
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
        self.navigationView.height = self.view.height - self.wrapView.height;
    } else {
        self.wrapView.hidden = YES;
        self.navigationView.height = self.view.height;
    }
    
    self.cameraNavigationController.view.frame = self.navigationView.bounds;
    [self.navigationView addSubview:self.cameraNavigationController.view];
    
	[self.cameraNavigationController setViewControllers:@[self.cameraViewController]];
}

- (UINavigationController *)cameraNavigationController {
    if (!_cameraNavigationController) {
        UINavigationController* controller = [[UINavigationController alloc] init];
        controller.navigationBarHidden = YES;
        [self addChildViewController:controller];
        [controller didMoveToParentViewController:self];
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

- (void)cropImage:(UIImage*)image completion:(void (^)(UIImage *croppedImage))completion {
	__weak typeof(self)weakSelf = self;
	CGSize viewSize = self.cameraViewController.viewSize;
	run_getting_object(^id{
		UIImage *result = nil;
		CGFloat width = weakSelf.mode;
		result = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
											 bounds:CGSizeMake(width, width)
							   interpolationQuality:kCGInterpolationDefault];
		if (weakSelf.mode != WLCameraModeCandy) {
			result = [result croppedImage:CGRectThatFitsSize(result.size, viewSize)];
		}
		return result;
	}, completion);
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
	__weak typeof(self)weakSelf = self;
	[gallery setSelectionBlock:^(ALAsset *asset) {
        ALAssetRepresentation* representation = asset.defaultRepresentation;
		UIImage* image = [UIImage imageWithCGImage:representation.fullResolutionImage scale:representation.scale orientation:(UIImageOrientation)representation.orientation];
		weakSelf.view.userInteractionEnabled = NO;
		[weakSelf cropImage:image completion:^(UIImage *croppedImage) {
			[weakSelf editImage:croppedImage];
			weakSelf.view.userInteractionEnabled = YES;
		}];
	}];
	[self.cameraNavigationController pushViewController:gallery animated:YES];
}

#pragma mark - AFPhotoEditorControllerDelegate

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image {
	[self.delegate stillPictureViewController:self didFinishWithImage:image];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor {
	[self.cameraNavigationController popViewControllerAnimated:YES];
}

@end
