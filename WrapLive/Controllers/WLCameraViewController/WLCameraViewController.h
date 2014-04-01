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

@protocol WLCameraViewControllerDelegate <NSObject>

- (void)cameraViewController:(WLCameraViewController*)controller didFinishWithImage:(UIImage*)image;
- (void)cameraViewControllerDidCancel:(WLCameraViewController*)controller;

@end

typedef NS_ENUM(NSInteger, WLCameraMode) {
	WLCameraModeSquare,
	WLCameraModeFullSize
};

@interface WLCameraViewController : UIViewController

@property (nonatomic, weak) id <WLCameraViewControllerDelegate> delegate;

@property (nonatomic) WLCameraMode mode;

@property (nonatomic) BOOL backfacingByDefault;

@end
