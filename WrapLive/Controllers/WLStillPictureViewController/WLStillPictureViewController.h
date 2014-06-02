//
//  WLStillPictureViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 30.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLCameraViewController.h"

@class WLStillPictureViewController;
@class WLCameraViewController;
@class WLWrap;

@protocol WLStillPictureViewControllerDelegate <UINavigationControllerDelegate>

- (void)stillPictureViewController:(WLStillPictureViewController*)controller didFinishWithImage:(UIImage*)image;

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController*)controller;

@end

@interface WLStillPictureViewController : UINavigationController

@property (nonatomic, weak) id <WLStillPictureViewControllerDelegate> delegate;

@property (strong, nonatomic) WLCameraViewController *cameraViewController;

@property (nonatomic) WLCameraMode mode;

@property (nonatomic) AVCaptureDevicePosition defaultPosition;

@property (strong, nonatomic) WLWrap* wrap;

@end
