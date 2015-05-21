//
//  WLHomeViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBaseViewController.h"
#import "WLStillPictureViewController.h"

@interface WLHomeViewController : WLBaseViewController <WLStillPictureViewControllerDelegate>

- (void)openCameraAnimated:(BOOL)animated startFromGallery:(BOOL)startFromGallery showWrapPicker:(BOOL)showPicker;

@end
