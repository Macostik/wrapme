//
//  WLCameraViewController.h
//  meWrap
//
//  Created by Ravenpod on 10.04.13.
//
//

#import "WLStillPictureBaseViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "WLQuickAssetsViewController.h"
#import "WLButton.h"

@class WLCameraViewController, PHAsset;

@protocol WLCameraViewControllerDelegate <WLStillPictureBaseViewControllerDelegate, WLQuickAssetsViewControllerDelegate>

- (void)cameraViewController:(WLCameraViewController*)controller didFinishWithImage:(UIImage*)image saveToAlbum:(BOOL)saveToAlbum;
- (void)cameraViewControllerDidCancel:(WLCameraViewController*)controller;

@optional
- (void)cameraViewController:(WLCameraViewController*)controller didFinishWithVideoAtPath:(NSString*)path saveToAlbum:(BOOL)saveToAlbum;
- (void)cameraViewControllerDidFinish:(WLCameraViewController*)controller;
- (BOOL)cameraViewControllerCaptureMedia:(WLCameraViewController*)controller;

@end

@interface WLCameraViewController : WLStillPictureBaseViewController

@property (weak, nonatomic) IBOutlet WLButton *finishButton;

@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;

@property (weak, nonatomic) IBOutlet WLWrapView *wrapView;

@property (nonatomic, weak) id <WLCameraViewControllerDelegate> delegate;

@property (nonatomic) AVCaptureDevicePosition position;

- (void)setPosition:(AVCaptureDevicePosition)position animated:(BOOL)animated;

@end
