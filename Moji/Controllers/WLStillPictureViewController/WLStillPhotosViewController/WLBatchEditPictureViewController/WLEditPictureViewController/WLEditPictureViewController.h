//
//  WLEditPictureViewController.h
//  moji
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLImageView;

@interface WLEditPictureViewController : UIViewController

@property (weak, nonatomic, readonly) WLImageView *imageView;

@property (strong, nonatomic) WLEditPicture* picture;

- (void)updateDeletionState;

@end
