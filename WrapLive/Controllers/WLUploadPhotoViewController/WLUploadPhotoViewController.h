//
//  WLUploadPhotoViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStillPictureBaseViewController.h"
#import <AdobeCreativeSDKImage/AdobeCreativeSDKImage.h>
#import <AdobeCreativeSDKFoundation/AdobeCreativeSDKFoundation.h>

typedef void (^WLUploadPhotoCompletionBlock) (UIImage *image, NSString *comment);

@interface WLUploadPhotoViewController : WLStillPictureBaseViewController

@property (strong, nonatomic) UIImage* image;

@property (strong, nonatomic) WLUploadPhotoCompletionBlock completionBlock;

@end

typedef void(^WLImageEditingCompletionBlock) (UIImage *image, AdobeUXImageEditorViewController *controller);
typedef void(^WLImageEditingCancelBlock) (AdobeUXImageEditorViewController *controller);

@interface AdobeUXImageEditorViewController (AviaryController)

+ (void)editImage:(UIImage*)image completion:(WLImageBlock)completion cancel:(WLBlock)cancel;

+ (AFPhotoEditorController*)editControllerWithImage:(UIImage*)image completion:(WLImageEditingCompletionBlock)completion cancel:(WLImageEditingCancelBlock)cancel;

@end
