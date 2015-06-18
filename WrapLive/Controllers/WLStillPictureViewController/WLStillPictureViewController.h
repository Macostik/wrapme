//
//  WLStillPictureViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 30.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"
#import <AVFoundation/AVCaptureDevice.h>
#import "WLCameraViewController.h"
#import "WLAssetsGroupViewController.h"

@class WLStillPictureViewController;
@class ALAsset;

@protocol WLStillPictureViewControllerDelegate <WLStillPictureBaseViewControllerDelegate, UINavigationControllerDelegate>

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController*)controller;

@optional

- (void)stillPictureViewController:(WLStillPictureViewController*)controller didFinishWithPictures:(NSArray*)pictures;

- (WLStillPictureMode)stillPictureViewControllerMode:(WLStillPictureViewController*)controller;

@end

@interface WLStillPictureViewController : UINavigationController <WLStillPictureBaseViewController, WLCameraViewControllerDelegate, WLAssetsViewControllerDelegate>

@property (nonatomic, weak) id <WLStillPictureViewControllerDelegate> delegate;

@property (nonatomic) BOOL startFromGallery;

@property (weak, nonatomic) WLCameraViewController *cameraViewController;

+ (instancetype)stillPictureViewController;

- (void)showWrapPickerWithController:(BOOL)animated;

- (void)showHintView;

- (id<WLStillPictureViewControllerDelegate>)getValidDelegate;

- (void)cropImage:(UIImage*)image completion:(void (^)(UIImage *croppedImage))completion;

- (void)cropAsset:(ALAsset*)asset completion:(void (^)(UIImage *croppedImage))completion;

- (void)openGallery:(BOOL)openCameraRoll animated:(BOOL)animated;

- (void)handleImage:(UIImage*)image metadata:(NSMutableDictionary *)metadata saveToAlbum:(BOOL)saveToAlbum;

- (void)finishWithPictures:(NSArray*)pictures;

@end
