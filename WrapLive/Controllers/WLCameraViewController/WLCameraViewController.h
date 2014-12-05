//
//  WLCameraViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10.04.13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class WLCameraViewController;
@class WLWrap;

@protocol WLCameraViewControllerDelegate <NSObject>

- (void)cameraViewController:(WLCameraViewController*)controller didFinishWithImage:(UIImage*)image metadata:(NSMutableDictionary*)metadata;
- (void)cameraViewControllerDidCancel:(WLCameraViewController*)controller;
- (void)cameraViewControllerDidSelectGallery:(WLCameraViewController*)controller;

@end

@interface WLCameraViewController : UIViewController

@property (nonatomic, weak) id <WLCameraViewControllerDelegate> delegate;

@property (nonatomic) AVCaptureDevicePosition defaultPosition;

@property (nonatomic) AVCaptureDevicePosition position;

- (void)setPosition:(AVCaptureDevicePosition)position animated:(BOOL)animated;

@end
