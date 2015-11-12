//
//  PHPhotoLibrary+Helper.m
//  16wrap
//
//  Created by Ravenpod on 01/09/15.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "PHPhotoLibrary+Helper.h"

@implementation PHPhotoLibrary (Helper)

+ (void)addImage:(UIImage *)image collectionTitle:(NSString *)title success:(WLBlock)success failure:(WLFailureBlock)failure {
    [self addAsset:^PHAssetChangeRequest *{
        return [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } collectionTitle:title success:success failure:failure];
}

+ (void)addImageAtFileUrl:(NSURL *)url collectionTitle:(NSString *)title success:(WLBlock)success failure:(WLFailureBlock)failure {
    [self addAsset:^PHAssetChangeRequest *{
        return [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
    } collectionTitle:title success:success failure:failure];
}

+ (void)addVideoAtFileUrl:(NSURL *)url collectionTitle:(NSString *)title success:(WLBlock)success failure:(WLFailureBlock)failure {
    [self addAsset:^PHAssetChangeRequest *{
        return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
    } collectionTitle:title success:success failure:failure];
}

+ (PHAssetCollectionChangeRequest *)collectionWithTitle:(NSString *)title {
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                                         subtype:PHAssetCollectionSubtypeAlbumRegular
                                                                                         options:nil];
    for (PHAssetCollection * collection in result) {
        if ([collection.localizedTitle isEqualToString:title]) {
            return [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        }
    }
    return [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
}

+ (void)addAsset:(PHAssetChangeRequest *(^)(void))assetBlock collectionTitle:(NSString *)title success:(WLBlock)success failure:(WLFailureBlock)failure {
    [[self sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest * assetChangeRequest = assetBlock();
        if  (assetChangeRequest) {
            PHAssetCollectionChangeRequest *collectonRequest = [self collectionWithTitle:title];
            PHObjectPlaceholder *asset = [assetChangeRequest placeholderForCreatedAsset];
            if (asset) {
                [collectonRequest addAssets:@[asset]];
            }
        }
    } completionHandler:^(BOOL s, NSError * _Nullable error) {
        run_in_main_queue(^{
            if (error) {
                if (failure) failure(error);
            } else {
                if (success) success();
            }
        });
    }];
}

@end

