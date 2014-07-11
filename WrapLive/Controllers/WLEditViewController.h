//
//  WLEditViewController.h
//  WrapLive
//
//  Created by Yuriy Granchenko on 10.07.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLShakeViewController.h"
#import "WLCameraViewController.h"
#import "WLStillPictureViewController.h"
#import "WLEditSession.h"

@interface WLEditViewController : WLShakeViewController 

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) WLEditSession *editSession;

@property (assign, nonatomic) AVCaptureDevicePosition stillPictureCameraPosition;
@property (assign, nonatomic) WLCameraMode stillPictureMode;

- (void)willShowDoneButton:(BOOL)showDone;
- (BOOL)isAtObjectSessionChanged;
- (void)updateIfNeeded:(void (^)(void))completion;
- (void)saveImage:(UIImage *)image;
- (void)lock;
- (void)unlock;

@end
