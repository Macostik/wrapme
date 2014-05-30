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

@interface WLStillPictureViewController () <WLCameraViewControllerDelegate, AFPhotoEditorControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation WLStillPictureViewController

@synthesize mode = _mode;

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setViewControllers:@[self.cameraViewController]];
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
	[self pushViewController:[self editControllerWithImage:image] animated:YES];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.view.userInteractionEnabled = NO;
	__weak typeof(self)weakSelf = self;
	[self cropImage:image completion:^(UIImage *croppedImage) {
		[weakSelf editImage:croppedImage];
		weakSelf.view.userInteractionEnabled = YES;
	}];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self.delegate stillPictureViewControllerDidCancel:self];
}

- (void)cameraViewControllerDidSelectGallery:(WLCameraViewController *)controller {
//	WLAssetsGroupViewController* gallery = [[WLAssetsGroupViewController alloc] init];
//	__weak typeof(self)weakSelf = self;
//	[gallery setSelectionBlock:^(ALAsset *asset) {
//		UIImage* image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage];
//		weakSelf.view.userInteractionEnabled = NO;
//		[weakSelf cropImage:image completion:^(UIImage *croppedImage) {
//			[weakSelf editImage:croppedImage];
//			weakSelf.view.userInteractionEnabled = YES;
//		}];
//	}];
//	[self pushViewController:gallery animated:YES];
	UIImagePickerController* galleryController = [[UIImagePickerController alloc] init];
	galleryController.allowsEditing = NO;
	galleryController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	galleryController.mediaTypes = @[(id)kUTTypeImage];
	galleryController.delegate = self;
	[self presentViewController:galleryController animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
	__weak typeof(self)weakSelf = self;
	self.view.userInteractionEnabled = NO;
	__block UIImage* croppedImage = nil;
	__block BOOL dismissed = NO;
	void (^completion)(void) = ^{
		[weakSelf editImage:croppedImage];
		weakSelf.view.userInteractionEnabled = YES;
	};
	
	[weakSelf cropImage:image completion:^(UIImage *_croppedImage) {
		croppedImage = _croppedImage;
		if (dismissed) {
			completion();
		}
	}];
	
	[self dismissViewControllerAnimated:YES completion:^{
		dismissed = YES;
		if (croppedImage) {
			completion();
		}
	}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AFPhotoEditorControllerDelegate

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image {
	[self.delegate stillPictureViewController:self didFinishWithImage:image];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor {
	[self popViewControllerAnimated:YES];
}

@end
