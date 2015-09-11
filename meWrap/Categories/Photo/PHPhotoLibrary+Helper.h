//
//  PHPhotoLibrary+Helper.h
//  16wrap
//
//  Created by Ravenpod on 01/09/15.
//  Copyright (c) 2014 Ravenpod. All rights reserved.

#import <Photos/Photos.h>
#import <meWrapKit/SupportHeaders.h>
#import <meWrapKit/WLCandy.h>
#import <meWrapKit/WLCollection.h>

@class Photos;

@interface PHFetchResult (Extended)

- (NSArray *)array;

@end

@interface NSObject (PHPhotoLibraryObserver) <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) WLObjectBlock changeObserver;

@end

@interface PHPhotoLibrary (Helper)

+ (void)addNewAssetWithImage:(UIImage *)image
  toAssetCollectionWithTitle:(NSString *)title
           completionHandler:(WLCompletionBlock)completion;

+ (void)addNewAssetWithImageAtFileUrl:(NSURL *)url
           toAssetCollectionWithTitle:(NSString *)title
                    completionHandler:(WLCompletionBlock)completion;

+ (void)addNewAssetWithVideoAtFileUrl:(NSURL *)url
           toAssetCollectionWithTitle:(NSString *)title
                    completionHandler:(WLCompletionBlock)completion;

+ (PHAssetCollectionChangeRequest *)assetCollectionWithTitle:(NSString *)title;

@end

@interface PHObject (Extended)

+ (PHFetchResult *)assetObjectnWithType:(NSInteger)type
                                subType:(NSInteger)subType;

+ (PHFetchResult *)assetObjectnWithType:(NSInteger)type
                                subType:(NSInteger)subType
                              predicate:(NSPredicate *)predicate;

+ (PHFetchResult *)assetObjectnWithType:(NSInteger)type
                                subType:(NSInteger)subType
                     sortDescriptionKey:(NSString *)descriptionKey;

+ (PHFetchResult *)assetObjectWithType:(NSInteger)type
                               subType:(NSInteger)subType
                    sortDescriptionKey:(NSString *)descriptionKey
                             ascending:(BOOL)ascending;

+ (PHFetchResult *)assetObjectWithType:(NSInteger)type
                               subType:(NSInteger)subType
                             predicate:(NSPredicate *)predicate
                    sortDescriptionKey:(NSString *)descriptionKey
                             ascending:(BOOL)ascending;

+ (NSArray *)allAssetObjects;

+ (PHFetchResult *)fetchAssetObjectWithType:(NSInteger)type
                                    subType:(NSInteger)subType
                                    options:(PHFetchOptions *)options;

@end

@interface PHAsset (Extended)

- (void)applyFilterWithName:(NSString *)filterName;

- (void)applyFilterWithName:(NSString *)filterName completionHandler:(WLCompletionBlock)completion;

@end

@interface PHAssetCollection (Extended)@end

@interface PHCollectionList (Extended)@end

@interface WLCandy (Photo)

- (void)download:(WLBlock)success failure:(WLFailureBlock)failure;

@end

@interface UIImage (Photo)

- (void)saveToAlbum;

- (void)saveToAlbum:(void (^)(void))completion failure:(void (^)(NSError *))failure;

@end

@interface PHFetchResult (Photo) <WLBaseOrderedCollection>

@end

