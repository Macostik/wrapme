//
//  PHPhotoLibrary+Helper.h
//  16wrap
//
//  Created by Ravenpod on 01/09/15.
//  Copyright (c) 2014 Ravenpod. All rights reserved.

#import <Photos/Photos.h>

@class Photos;

@interface PHPhotoLibrary (Helper)

+ (void)addNewAssetWithImage:(UIImage *)image toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion;

+ (void)addNewAssetWithImageAtFileUrl:(NSURL *)url toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion;

+ (void)addNewAssetWithVideoAtFileUrl:(NSURL *)url toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion;

@end
