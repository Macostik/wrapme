//
//  WLStillPictureViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 30.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"
#import <AVFoundation/AVCaptureDevice.h>

@class WLStillPictureViewController;
@class WLCameraViewController;
@class WLWrap;

@protocol WLStillPictureViewControllerDelegate <WLStillPictureBaseViewControllerDelegate>

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController*)controller;

@optional

- (void)stillPictureViewController:(WLStillPictureViewController*)controller didFinishWithPictures:(NSArray*)pictures;

- (WLStillPictureMode)stillPictureViewControllerMode:(WLStillPictureViewController*)controller;

@end

@interface WLStillPictureViewController : WLStillPictureBaseViewController

@property (weak, nonatomic, readonly) UINavigationController* cameraNavigationController;

@property (nonatomic, weak) id <WLStillPictureViewControllerDelegate> delegate;

@property (nonatomic) AVCaptureDevicePosition defaultPosition;

@property (nonatomic) BOOL startFromGallery;

@end
