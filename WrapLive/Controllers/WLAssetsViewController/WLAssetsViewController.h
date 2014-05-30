//
//  PGPhotoLibraryViewController.h
//  PressGram-iOS
//
//  Created by Andrey Ivanov on 30.05.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALAssetsGroup;
@class ALAsset;

@interface WLAssetsViewController : UIViewController

- (id)initWithGroup:(ALAssetsGroup*)group;

@property (strong, nonatomic) ALAssetsGroup* group;

@property (copy, nonatomic) void (^selectionBlock) (ALAsset* asset);

@end
