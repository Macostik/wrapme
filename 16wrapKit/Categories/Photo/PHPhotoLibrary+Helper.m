//
//  PHPhotoLibrary+Helper.m
//  16wrap
//
//  Created by Ravenpod on 01/09/15.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "PHPhotoLibrary+Helper.h"

@implementation PHPhotoLibrary (Helper)

+ (void)addNewAssetWithImage:(UIImage *)image toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion {
    [self performChangesForCollectionWithTitle:title forImage:image completionHandler:completion];
}

+ (void)addNewAssetWithImageAtFileUrl:(NSURL *)url toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion {
    [self performChangesForCollectionWithTitle:title forImageAtFileUrl:url completionHandler:completion];
}

+ (void)addNewAssetWithVideoAtFileUrl:(NSURL *)url toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion {
    [self performChangesForCollectionWithTitle:title forVideoAtFileUrl:url completionHandler:completion];
}

+ (PHAssetCollectionChangeRequest *)assetCollectionWithTitle:(NSString *)title {
    PHFetchOptions *options = [PHFetchOptions new];
    options.predicate = [NSPredicate predicateWithFormat:@"localizedTitle == %@", title];
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:options];
    PHAssetCollectionChangeRequest *collectionChangeRequest = nil;
    if (result.count > 0) {
        collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:result.firstObject];
    } else {
        collectionChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
    }
    return collectionChangeRequest;
}

+ ( void)performChanges:(dispatch_block_t)changeBlock forAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion {
    [[self sharedPhotoLibrary] performChanges:changeBlock completionHandler:completion];
}

+ (void)performChangesForCollectionWithTitle:(NSString *)title
                                    forImage:(UIImage *)image
                           completionHandler:(WLCompletionBlock)completion {
    [[self sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        PHAssetCollectionChangeRequest *collectonRequest = [self assetCollectionWithTitle:title];
        [collectonRequest addAssets:@[[assetRequest placeholderForCreatedAsset]]];
    } completionHandler:completion];
}

+ (void)performChangesForCollectionWithTitle:(NSString *)title
                           forImageAtFileUrl:(NSURL *)url
                           completionHandler:(WLCompletionBlock)completion {
    [[self sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
        PHAssetCollectionChangeRequest *collectonRequest = [self assetCollectionWithTitle:title];
        [collectonRequest addAssets:@[[assetRequest placeholderForCreatedAsset]]];
    } completionHandler:completion];
}

+ (void)performChangesForCollectionWithTitle:(NSString *)title
                           forVideoAtFileUrl:(NSURL *)url
                           completionHandler:(WLCompletionBlock)completion {
    [[self sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        PHAssetCollectionChangeRequest *collectonRequest = [self assetCollectionWithTitle:title];
        [collectonRequest addAssets:@[[assetRequest placeholderForCreatedAsset]]];
    } completionHandler:completion];
}

@end
