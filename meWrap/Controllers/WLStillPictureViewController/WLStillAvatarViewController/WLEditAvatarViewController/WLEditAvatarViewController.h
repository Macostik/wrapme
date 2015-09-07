//
//  WLUploadPhotoViewController.h
//  meWrap
//
//  Created by Ravenpod on 2/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"

typedef void (^WLUploadPhotoCompletionBlock) (UIImage *image, NSString *comment);

@interface WLEditAvatarViewController : WLStillPictureBaseViewController

@property (strong, nonatomic) UIImage* image;

@property (strong, nonatomic) WLUploadPhotoCompletionBlock completionBlock;

@end
