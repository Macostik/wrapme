//
//  WLUploadPhotoViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"

@interface WLUploadPhotoViewController : WLStillPictureBaseViewController

@property (strong, nonatomic) UIImage* image;

@property (strong, nonatomic) WLImageBlock completionBlock;

@end
