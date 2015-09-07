//
//  AdobeUXImageEditorViewController+SharedEditing.h
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <AdobeCreativeSDKImage/AdobeCreativeSDKImage.h>

typedef void(^WLImageEditingCompletionBlock) (UIImage *image, AdobeUXImageEditorViewController *controller);
typedef void(^WLImageEditingCancelBlock) (AdobeUXImageEditorViewController *controller);

@interface AdobeUXImageEditorViewController (SharedEditing)

+ (void)editImage:(UIImage*)image completion:(WLImageBlock)completion cancel:(WLBlock)cancel;

+ (AFPhotoEditorController*)editControllerWithImage:(UIImage*)image completion:(WLImageEditingCompletionBlock)completion cancel:(WLImageEditingCancelBlock)cancel;

@end
