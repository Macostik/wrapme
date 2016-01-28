//
//  WLCameraViewController.h
//  meWrap
//
//  Created by Ravenpod on 10.04.13.
//
//

#import "WLStillPictureBaseViewController.h"
#import <AVFoundation/AVFoundation.h>

@class WLCameraViewController, PHAsset, Button;

@protocol AssetsViewControllerDelegate;

@protocol WLCameraViewControllerDelegate <WLStillPictureBaseViewControllerDelegate, AssetsViewControllerDelegate>

- (void)cameraViewController:(WLCameraViewController*)controller didCaptureImage:(UIImage*)image saveToAlbum:(BOOL)saveToAlbum;
- (void)cameraViewControllerDidCancel:(WLCameraViewController*)controller;

@optional
- (void)cameraViewControllerDidFailImageCapturing:(WLCameraViewController*)controller;
- (void)cameraViewControllerWillCaptureImage:(WLCameraViewController*)controller;
- (void)cameraViewController:(WLCameraViewController*)controller didCaptureVideoAtPath:(NSString*)path saveToAlbum:(BOOL)saveToAlbum;
- (void)cameraViewControllerDidFinish:(WLCameraViewController*)controller;
- (BOOL)cameraViewControllerCanCaptureMedia:(WLCameraViewController*)controller;

@end

@interface WLCameraViewController : WLStillPictureBaseViewController

@property (weak, nonatomic) IBOutlet Button *finishButton;

@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;

@property (weak, nonatomic) IBOutlet WrapView *wrapView;

@property (nonatomic, weak) id <WLCameraViewControllerDelegate> delegate;

@property (nonatomic) AVCaptureDevicePosition position;

- (void)setPosition:(AVCaptureDevicePosition)position animated:(BOOL)animated;

@end
