//
//  ALAssetsLibrary+CustomPhotoAlbum.h
//  PressGram-iOS
//
//  Created by Alexandr Snegursky on 7/5/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAssetsLibrary (CustomPhotoAlbum)

- (void)saveImage:(UIImage *)image
         toAlbum:(NSString *)albumName
      completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
         failure:(ALAssetsLibraryAccessFailureBlock)failure;
- (void)saveImage:(UIImage *)image
              toAlbum:(NSString *)albumName
             metadata:(NSDictionary *)metadata
           completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
          failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (void)saveImageData:(NSData *)imageData
              toAlbum:(NSString *)albumName
             metadata:(NSDictionary *)metadata
           completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
              failure:(ALAssetsLibraryAccessFailureBlock)failure;

@end
