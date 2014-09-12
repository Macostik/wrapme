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
#import "WLImageFetcher.h"
#import "WLBorderView.h"

@interface WLEditViewController : WLShakeViewController 

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet WLBorderView *imagePlaceholderView;

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
