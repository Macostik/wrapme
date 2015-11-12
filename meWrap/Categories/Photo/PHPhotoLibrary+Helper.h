//
//  PHPhotoLibrary+Helper.h
//  16wrap
//
//  Created by Ravenpod on 01/09/15.
//  Copyright (c) 2014 Ravenpod. All rights reserved.

#import <Photos/Photos.h>

@interface PHPhotoLibrary (Helper)

+ (void)addImage:(UIImage *)image collectionTitle:(NSString *)title success:(WLBlock)success failure:(WLFailureBlock)failure;

+ (void)addImageAtFileUrl:(NSURL *)url collectionTitle:(NSString *)title success:(WLBlock)success failure:(WLFailureBlock)failure;

+ (void)addVideoAtFileUrl:(NSURL *)url collectionTitle:(NSString *)title success:(WLBlock)success failure:(WLFailureBlock)failure;

+ (void)addAsset:(PHAssetChangeRequest *(^)(void))assetBlock collectionTitle:(NSString *)title success:(WLBlock)success failure:(WLFailureBlock)failure;

+ (PHAssetCollectionChangeRequest *)collectionWithTitle:(NSString *)title;

@end

