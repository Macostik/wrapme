//
//  PGPhotoGroupViewController.h
//  PressGram-iOS
//
//  Created by Ivanov Andrey on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLCameraViewController.h"

@class ALAsset;

@interface WLAssetsGroupViewController : UIViewController

@property (copy, nonatomic) WLArrayBlock selectionBlock;

@property (nonatomic) WLCameraMode mode;

@end
