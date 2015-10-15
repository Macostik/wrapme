//
//  PHPhotoLibrary+Helper.m
//  16wrap
//
//  Created by Ravenpod on 01/09/15.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "PHPhotoLibrary+Helper.h"
#import "NSString+Additions.h"
#import "DefinedBlocks.h"
#import "NSObject+AssociatedObjects.h"
#import "WLToast.h"

@implementation PHFetchResult (Extended)

- (NSArray *)array {
    return [self objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, MAX(self.count - 1, 0))]];
}

@end

@implementation NSObject (PHPhotoLibraryObserver)

- (void)setChangeObserver:(WLObjectBlock)changeObserver {
    [self setAssociatedObject:changeObserver forKey:"wl_observerBlock"];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (WLObjectBlock)changeObserver {
    return [self associatedObjectForKey:"wl_observerBlock"];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if (self.changeObserver) {
        self.changeObserver(changeInstance);
    }
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

@end

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

@implementation PHObject (Extended)

+ (PHFetchResult *)assetObjectnWithType:(NSInteger)type
                                subType:(NSInteger)subType {
    return [self assetObjectWithType:type subType:subType predicate:nil sortDescriptionKey:nil ascending:YES];
}

+ (PHFetchResult *)assetObjectnWithType:(NSInteger)type
                                subType:(NSInteger)subType
                              predicate:(NSPredicate *)predicate {
    return [self assetObjectWithType:type subType:subType predicate:predicate sortDescriptionKey:nil ascending:YES];
}

+ (PHFetchResult *)assetObjectnWithType:(NSInteger)type
                                subType:(NSInteger)subType
                     sortDescriptionKey:(NSString *)descriptionKey {
    return [self assetObjectWithType:type subType:subType sortDescriptionKey:descriptionKey ascending:YES];
}

+ (PHFetchResult *)assetObjectWithType:(NSInteger)type
                               subType:(NSInteger)subType
                    sortDescriptionKey:(NSString *)descriptionKey
                             ascending:(BOOL)ascending {
    return [self assetObjectWithType:type subType:subType predicate:nil sortDescriptionKey:descriptionKey ascending:ascending];
}

+ (PHFetchResult *)assetObjectWithType:(NSInteger)type
                               subType:(NSInteger)subType
                             predicate:(NSPredicate *)predicate
                    sortDescriptionKey:(NSString *)descriptionKey
                             ascending:(BOOL)ascending {
    PHFetchOptions *options = nil;
    if (predicate || descriptionKey.nonempty) {
        options = [PHFetchOptions new];
        options.predicate = predicate;
        options.sortDescriptors = descriptionKey.nonempty ? @[[NSSortDescriptor sortDescriptorWithKey:descriptionKey ascending:ascending]] : nil;
    }
    
    return [self fetchAssetObjectWithType:type subType:subType options:options];
}

+ (NSArray *)allAssetObjects {
    return nil;
}

+ (PHFetchResult *)fetchAssetObjectWithType:(NSInteger)type subType:(NSInteger)subType options:(PHFetchOptions *)options {
    return nil;
}

@end

@implementation PHAsset (Extended)

+ (NSArray *)allAssetObjects {
    return [[self assetObjectnWithType:PHAssetMediaTypeImage subType:PHAssetMediaSubtypeNone] array];
}

// MARK: - All filters - https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/filter/ci/

- (void)applyFilterWithName:(NSString *)filterName {
    [self applyFilterWithName:filterName completionHandler:nil];
}

- (void)applyFilterWithName:(NSString *)filterName completionHandler:(WLCompletionBlock)completion {
    PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
    [options setCanHandleAdjustmentData:^BOOL(PHAdjustmentData *adjustmentData) {
        return [adjustmentData.formatIdentifier isEqualToString: @"apply.filter.extension"] && [adjustmentData.formatVersion isEqualToString:@"1.0"];
    }];
    [self requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {

        NSURL *url = [contentEditingInput fullSizeImageURL];
        int orientation = [contentEditingInput fullSizeImageOrientation];
        CIImage *inputImage = [CIImage imageWithContentsOfURL:url options:nil];
        inputImage = [inputImage imageByApplyingOrientation:orientation];
        
        CIFilter *filter = [CIFilter filterWithName:filterName];
        [filter setDefaults];
        [filter setValue:inputImage forKey:kCIInputImageKey];
        CIImage *outputImage = [filter outputImage];
        
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
        
        UIImage* uiImage = [UIImage imageWithCGImage:cgImage];
        NSData *jpegData = UIImageJPEGRepresentation(uiImage, 1.0);
        PHAdjustmentData *adjustmentData = [[PHAdjustmentData alloc] initWithFormatIdentifier:@"apply.filter.extension" formatVersion:@"1.0" data:[filterName dataUsingEncoding:NSUTF8StringEncoding]];
        
        PHContentEditingOutput *contentEditingOutput = [[PHContentEditingOutput alloc] initWithContentEditingInput:contentEditingInput];
        [jpegData writeToURL:[contentEditingOutput renderedContentURL] atomically:YES];
        [contentEditingOutput setAdjustmentData:adjustmentData];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:self];
            request.contentEditingOutput = contentEditingOutput;
        } completionHandler:completion];
    }];
}

+ (PHFetchResult *)fetchAssetObjectWithType:(NSInteger)type subType:(__unused NSInteger)subType options:(PHFetchOptions *)options {
    return [self fetchAssetsWithMediaType:type options:options];
}

@end

@implementation PHAssetCollection (Extended)

+ (NSArray *)allAssetObjects {
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult *topLevelUserAlbums = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    NSMutableArray *collectionsAlbumResults = [NSMutableArray arrayWithArray:[smartAlbums array]];
    [collectionsAlbumResults addObjectsFromArray:[topLevelUserAlbums array]];
    return collectionsAlbumResults.mutableCopy;
}

+ (PHFetchResult *)fetchAssetObjectWithType:(NSInteger)type subType:(NSInteger)subType options:(PHFetchOptions *)options {
    return [self fetchAssetCollectionsWithType:type subtype:subType options:options];
}

@end

@implementation PHCollectionList (Extended)

+ (NSArray *)allAssetObjects {
    return [[self assetObjectnWithType:PHCollectionListTypeMomentList subType:PHCollectionListSubtypeAny] array];
}

+ (PHFetchResult *)fetchAssetObjectWithType:(NSInteger)type subType:(NSInteger)subType options:(PHFetchOptions *)options {
    return [self fetchCollectionListsWithType:type subtype:subType options:options];
}

@end

@implementation WLCandy (Photo)

- (void)download:(WLBlock)success failure:(WLFailureBlock)failure {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied) {
        if (failure) failure(WLError(WLLS(@"downloading_privacy_settings")));
    } else {
        __weak typeof(self)weakSelf = self;
        if (weakSelf.type == WLCandyTypeVideo) {
            NSString *url = weakSelf.picture.original;
            if ([[NSFileManager defaultManager] fileExistsAtPath:url]) {
                [PHPhotoLibrary addAsset:^PHAssetChangeRequest *{
                    return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:url]];
                } collectionTitle:WLAlbumName success:success failure:failure];
            } else {
                NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    if (error) {
                        if (failure) failure(error);
                    } else {
                        NSURL* url = [[location URLByDeletingPathExtension] URLByAppendingPathExtension:@"mp4"];
                        [[NSFileManager defaultManager] moveItemAtURL:location toURL:url error:nil];
                        [PHPhotoLibrary addAsset:^PHAssetChangeRequest *{
                            return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
                        } collectionTitle:WLAlbumName success:success failure:failure];
                    }
                }];
                [task resume];
            }
        } else {
            [[WLBlockImageFetching fetchingWithUrl:weakSelf.picture.original] enqueue:^(UIImage *image) {
                [PHPhotoLibrary addAsset:^PHAssetChangeRequest *{
                    return [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                } collectionTitle:WLAlbumName success:success failure:failure];
            } failure:failure];
        }
    }
}

@end

@implementation UIImage (Photo)

- (void)saveToAlbum {
    [self saveToAlbum:nil failure:nil];
}

- (void)saveToAlbum:(void (^)(void))success failure:(void (^)(NSError *))failure {
    [PHPhotoLibrary addAsset:^PHAssetChangeRequest *{
        return [PHAssetChangeRequest creationRequestForAssetFromImage:self];
    } collectionTitle:WLAlbumName success:success failure:failure];
}

@end

@implementation PHFetchResult (Photo)

- (id)tryAt:(NSUInteger)index {
    if (index < self.count) {
        return [self objectAtIndex:index];
    }
    return nil;
}

@end


