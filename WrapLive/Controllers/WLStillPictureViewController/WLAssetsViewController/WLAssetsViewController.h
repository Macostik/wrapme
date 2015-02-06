//
//  PGPhotoLibraryViewController.h
//  PressGram-iOS
//
//  Created by Andrey Ivanov on 30.05.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"

@class ALAssetsGroup;
@class ALAsset;
@class WLAssetsViewController;

@protocol WLAssetsViewControllerDelegate <WLStillPictureBaseViewControllerDelegate>

- (void)assetsViewController:(id)controller didSelectAssets:(NSArray*)assets;

@end

@interface WLAssetsViewController : WLStillPictureBaseViewController

@property (weak, nonatomic) id <WLAssetsViewControllerDelegate> delegate;

@property (strong, nonatomic) ALAssetsGroup* group;

@property (nonatomic) BOOL preselectFirstAsset;

- (id)initWithGroup:(ALAssetsGroup*)group;

@end
