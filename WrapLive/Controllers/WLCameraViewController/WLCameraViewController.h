//
//  WLCameraViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10.04.13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, WLCameraMode) {
	WLCameraModeCandy,
	WLCameraModeAvatar,
	WLCameraModeCover
};

@class WLCameraViewController;
@class WLWrap;

@protocol WLCameraViewControllerDelegate <NSObject>

- (void)cameraViewController:(WLCameraViewController*)controller didFinishWithImage:(UIImage*)image metadata:(NSMutableDictionary*)metadata;
- (void)cameraViewControllerDidCancel:(WLCameraViewController*)controller;
- (void)cameraViewControllerDidSelectGallery:(WLCameraViewController*)controller;

@end

@interface WLCameraViewController : UIViewController

@property (nonatomic, weak) id <WLCameraViewControllerDelegate> delegate;

@property (nonatomic) WLCameraMode mode;

@property (nonatomic) AVCaptureDevicePosition defaultPosition;

@property (nonatomic) AVCaptureDevicePosition position;

@property (readonly, nonatomic) CGSize viewSize;

@property (nonatomic) CGFloat bottomInset;

- (void)setPosition:(AVCaptureDevicePosition)position animated:(BOOL)animated;

@end
