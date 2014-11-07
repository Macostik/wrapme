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

@protocol WLStillPictureViewControllerDelegate <NSObject>

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController*)controller;

@optional

- (void)stillPictureViewController:(WLStillPictureViewController*)controller didFinishWithImage:(UIImage*)image;

- (void)stillPictureViewController:(WLStillPictureViewController*)controller didFinishWithPictures:(NSArray*)pictures;

@end

@interface WLStillPictureViewController : UIViewController
{
@private
    BOOL _editable:YES;
}

@property (weak, nonatomic, readonly) UINavigationController* cameraNavigationController;

@property (nonatomic, weak) id <WLStillPictureViewControllerDelegate> delegate;

@property (strong, nonatomic) WLCameraViewController *cameraViewController;

@property (nonatomic) WLCameraMode mode;

@property (nonatomic) AVCaptureDevicePosition defaultPosition;

@property (strong, nonatomic) WLWrap* wrap;

@property (nonatomic) BOOL editable;

- (void)willCreateWrap;

@end
