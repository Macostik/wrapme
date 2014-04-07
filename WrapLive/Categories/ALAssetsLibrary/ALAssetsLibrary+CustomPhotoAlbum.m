//
//  ALAssetsLibrary+CustomPhotoAlbum.m
//  PressGram-iOS
//
//  Created by Alexandr Snegursky on 7/5/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "ALAssetsLibrary+CustomPhotoAlbum.h"

@interface ALAssetsLibrary (Private)

- (void)_addAssetURL:(NSURL *)assetURL
             toAlbum:(NSString *)albumName
             failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (ALAssetsLibraryWriteImageCompletionBlock)_resultBlockOfAddingToAlbum:(NSString *)albumName
                                                             completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
                                                                failure:(ALAssetsLibraryAccessFailureBlock)failure;

@end


@implementation ALAssetsLibrary (CustomPhotoAlbum)


#pragma mark - Public Methods


- (void)saveImage:(UIImage *)image
          toAlbum:(NSString *)albumName
       completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
          failure:(ALAssetsLibraryAccessFailureBlock)failure
{
    [self writeImageToSavedPhotosAlbum:image.CGImage
                           orientation:(ALAssetOrientation)image.imageOrientation
                       completionBlock:[self _resultBlockOfAddingToAlbum:albumName
                                                              completion:completion
                                                                 failure:failure]];
}

- (void)saveImage:(UIImage *)image
          toAlbum:(NSString *)albumName
         metadata:(NSDictionary *)metadata
       completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
          failure:(ALAssetsLibraryAccessFailureBlock)failure;
{
    [self writeImageToSavedPhotosAlbum:image.CGImage metadata:metadata completionBlock:[self _resultBlockOfAddingToAlbum:albumName
                                                                                                              completion:completion
                                                                                                                 failure:failure]];
    
}

///////////////////////////////////////////////////////////////////////////////////////////////


- (void)saveImageData:(NSData *)imageData
              toAlbum:(NSString *)albumName
             metadata:(NSDictionary *)metadata
           completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
              failure:(ALAssetsLibraryAccessFailureBlock)failure
{
    [self writeImageDataToSavedPhotosAlbum:imageData
                                  metadata:metadata
                           completionBlock:[self _resultBlockOfAddingToAlbum:albumName
                                                                  completion:completion
                                                                     failure:failure]];
    
}


///////////////////////////////////////////////////////////////////////////////////////////////


#pragma mark - Private Methods


-(void)_addAssetURL:(NSURL *)assetURL
            toAlbum:(NSString *)albumName
            failure:(ALAssetsLibraryAccessFailureBlock)failure
{
    __block BOOL albumWasFound = NO;
    
    ALAssetsLibraryGroupsEnumerationResultsBlock enumerationBlock;
    enumerationBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        
        if ([albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame)
        {
            albumWasFound = YES;
            
            [self assetForURL:assetURL
                  resultBlock:^(ALAsset *asset) {
                      [group addAsset:asset];
                  }
                 failureBlock:failure];
            
            return;
        }
        
        if (group == nil && albumWasFound == NO)
        {
            ALAssetsLibrary * weakSelf = self;
            
            if (![self respondsToSelector:@selector(addAssetsGroupAlbumWithName:resultBlock:failureBlock:)])
            {
                NSLog(@"![WARNING][LIB:ALAssetsLibrary+CustomPhotoAlbum]: \
                      |-addAssetsGroupAlbumWithName:resultBlock:failureBlock:| \
                      only available on iOS 5.0 or later. \
                      ASSET cannot be saved to album!");
            }
            else
            {
                [self addAssetsGroupAlbumWithName:albumName
                                      resultBlock:^(ALAssetsGroup *group) {
                                          [weakSelf assetForURL:assetURL
                                                    resultBlock:^(ALAsset *asset) {
                                                        [group addAsset:asset];
                                                    }
                                                   failureBlock:failure];
                                      }
                                     failureBlock:failure];
            }
            
            return;
        }
    };
    
    [self enumerateGroupsWithTypes:ALAssetsGroupAlbum
                        usingBlock:enumerationBlock
                      failureBlock:failure];
}


///////////////////////////////////////////////////////////////////////////////////////////////


- (ALAssetsLibraryWriteImageCompletionBlock)_resultBlockOfAddingToAlbum:(NSString *)albumName
                                                             completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
                                                                failure:(ALAssetsLibraryAccessFailureBlock)failure
{
    ALAssetsLibraryWriteImageCompletionBlock result = ^(NSURL *assetURL, NSError *error) {
        if (completion)
        {
            completion(assetURL, error);
        }
        
        if (error)
        {
            return;
        }
        
        [self _addAssetURL:assetURL
                   toAlbum:albumName
                   failure:failure];
    };
    
    return [result copy];
}

@end
