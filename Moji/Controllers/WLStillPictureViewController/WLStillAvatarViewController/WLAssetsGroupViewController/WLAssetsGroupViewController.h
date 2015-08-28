//
//  PGPhotoGroupViewController.h
//  moji
//
//  Created by Ivanov Andrey on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"
#import "WLAssetsViewController.h"

@class ALAsset;

@interface WLAssetsGroupViewController : WLStillPictureBaseViewController

@property (weak, nonatomic) id <WLAssetsViewControllerDelegate> delegate;

@property (nonatomic) BOOL openCameraRoll;

@end
