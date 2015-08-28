//
//  WLCameraViewController.h
//  moji
//
//  Created by Ravenpod on 10.04.13.
//
//

#import "WLStillPictureBaseViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "WLQuickAssetsViewController.h"

@class WLCameraViewController, ALAsset;

@protocol WLCameraViewControllerDelegate <WLStillPictureBaseViewControllerDelegate, WLQuickAssetsViewControllerDelegate>

- (void)cameraViewController:(WLCameraViewController*)controller didFinishWithImage:(UIImage*)image metadata:(NSMutableDictionary*)metadata saveToAlbum:(BOOL)saveToAlbum;
- (void)cameraViewControllerDidCancel:(WLCameraViewController*)controller;

@optional
- (void)cameraViewControllerDidFinish:(WLCameraViewController*)controller sender:(id)sender;
- (BOOL)cameraViewControllerShouldTakePhoto:(WLCameraViewController*)controller;

@end

@interface WLCameraViewController : WLStillPictureBaseViewController

@property (weak, nonatomic) IBOutlet UIButton *finishButton;

@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;

@property (weak, nonatomic) IBOutlet WLWrapView *wrapView;

@property (nonatomic, weak) id <WLCameraViewControllerDelegate> delegate;

@property (nonatomic) AVCaptureDevicePosition position;

- (void)setPosition:(AVCaptureDevicePosition)position animated:(BOOL)animated;

@end
