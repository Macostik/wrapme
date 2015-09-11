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

static WLReturnObjectBlock assetCreaterBlock;

+ (void)addNewAssetWithImage:(UIImage *)image toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion {
    assetCreaterBlock = ^ {
        return [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    };
    [self performChangesForAssetCollectionWithTitle:title completionHandler:completion];
}

+ (void)addNewAssetWithImageAtFileUrl:(NSURL *)url toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion {
    assetCreaterBlock = ^ {
        return [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
    };
    [self performChangesForAssetCollectionWithTitle:title completionHandler:completion];
}

+ (void)addNewAssetWithVideoAtFileUrl:(NSURL *)url toAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion {
    assetCreaterBlock = ^ {
        return [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
    };
    [self performChangesForAssetCollectionWithTitle:title completionHandler:completion];
}

+ (PHAssetCollectionChangeRequest *)assetCollectionWithTitle:(NSString *)title {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title == %@", title];
    PHFetchResult *result = [PHAssetCollection assetObjectnWithType:PHAssetCollectionTypeAlbum
                                                            subType:PHAssetCollectionSubtypeAny
                                                          predicate:predicate];
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

+ (void)performChangesForAssetCollectionWithTitle:(NSString *)title completionHandler:(WLCompletionBlock)completion {
    [[self sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest * assetChangeRequest = assetCreaterBlock();
        if  (assetChangeRequest) {
            PHAssetCollectionChangeRequest *collectonRequest = [self assetCollectionWithTitle:title];
            PHObjectPlaceholder *asset = [assetChangeRequest placeholderForCreatedAsset];
            if (asset) {
                [collectonRequest addAssets:@[asset]];
            }
        }
    } completionHandler:completion];
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
        return;
    }
    
    [[WLBlockImageFetching fetchingWithUrl:self.picture.original] enqueue:^(UIImage *image) {
        [image saveToAlbum:success failure:failure];
    } failure:^(NSError *error) {
        if (error.isNetworkError) {
            error = WLError(WLLS(@"downloading_internet_connection_error"));
        }
        if (failure) failure(error);
    }];
}

@end

@implementation UIImage (Photo)

- (void)saveToAlbum {
    [self saveToAlbum:nil failure:nil];
}

- (void)saveToAlbum:(void (^)(void))completion failure:(void (^)(NSError *))failure {
    [PHPhotoLibrary addNewAssetWithImage:self toAssetCollectionWithTitle:WLAlbumName completionHandler:^(BOOL success, NSError *error) {
        run_in_main_queue(^{
            if (error) {
                if (failure) failure(error);
            } else {
                if (completion) completion();
            }
        });
    }];
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


