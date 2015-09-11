//
//  PHPhotoLibrary+WLHelper.h
//  Moji
//
//  Created by Yura Granchenko on 01/09/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Photos/Photos.h>

@import Photos;

@interface PHPhotoLibrary (WLHelper)

+ (void)addImage:(UIImage *)image toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion;

+ (void)addImageAtFileUrl:(NSURL *)url toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion;

+ (void)addVideoAtFileUrl:(NSURL *)url toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion;

@end
