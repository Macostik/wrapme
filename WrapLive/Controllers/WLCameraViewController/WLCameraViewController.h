//
//  WLCameraViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10.04.13.
//
//

#import "WLStillPictureBaseViewController.h"
#import <AVFoundation/AVFoundation.h>

@class WLCameraViewController;
@class WLWrap;

@protocol WLCameraViewControllerDelegate <WLStillPictureBaseViewControllerDelegate>

- (void)cameraViewController:(WLCameraViewController*)controller didFinishWithImage:(UIImage*)image metadata:(NSMutableDictionary*)metadata;
- (void)cameraViewControllerDidCancel:(WLCameraViewController*)controller;
- (void)cameraViewControllerDidSelectGallery:(WLCameraViewController*)controller;

@end

@interface WLCameraViewController : WLStillPictureBaseViewController

@property (nonatomic, weak) id <WLCameraViewControllerDelegate> delegate;

@property (nonatomic) AVCaptureDevicePosition defaultPosition;

@property (nonatomic) AVCaptureDevicePosition position;

- (void)setPosition:(AVCaptureDevicePosition)position animated:(BOOL)animated;

@end
