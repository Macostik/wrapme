//
//  WLEditPictureViewController.h
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageView, WLEditPicture;

@interface WLEditPictureViewController : UIViewController

@property (weak, nonatomic, readonly) ImageView *imageView;

@property (strong, nonatomic) MutableAsset *picture;

- (void)updateDeletionState;

@end
