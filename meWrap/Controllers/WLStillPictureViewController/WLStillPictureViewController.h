//
//  WLStillPictureViewController.h
//  meWrap
//
//  Created by Ravenpod on 30.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"
#import <AVFoundation/AVCaptureDevice.h>
#import "WLCameraViewController.h"

@class WLStillPictureViewController;

@protocol WLStillPictureViewControllerDelegate <WLStillPictureBaseViewControllerDelegate, UINavigationControllerDelegate>

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController*)controller;

@optional

- (void)stillPictureViewController:(WLStillPictureViewController*)controller didFinishWithPictures:(NSArray*)pictures;

- (StillPictureMode)stillPictureViewControllerMode:(WLStillPictureViewController*)controller;

@end

@interface WLStillPictureViewController : UINavigationController <WLStillPictureBaseViewController, WLCameraViewControllerDelegate>

@property (nonatomic, weak) id <WLStillPictureViewControllerDelegate> delegate;

@property (nonatomic) BOOL startFromGallery;

@property (weak, nonatomic) WLCameraViewController *cameraViewController;

+ (instancetype)stillPhotosViewController;

+ (instancetype)stillAvatarViewController;

- (void)showWrapPickerWithController:(BOOL)animated;

- (id<WLStillPictureViewControllerDelegate>)getValidDelegate;

- (void)cropImage:(UIImage*)image completion:(void (^)(UIImage *croppedImage))completion;

- (void)cropAsset:(PHAsset*)asset completion:(void (^)(UIImage *croppedImage))completion;

- (void)handleImage:(UIImage*)image saveToAlbum:(BOOL)saveToAlbum;

- (void)finishWithPictures:(NSArray*)pictures;

@end
