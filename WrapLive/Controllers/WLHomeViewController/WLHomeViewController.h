//
//  WLHomeViewController.h
//  moji
//
//  Created by Ravenpod on 19.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"
#import "WLStillPictureViewController.h"

@interface WLHomeViewController : WLBaseViewController <WLStillPictureViewControllerDelegate>

- (void)openCameraAnimated:(BOOL)animated startFromGallery:(BOOL)startFromGallery showWrapPicker:(BOOL)showPicker;

@end
