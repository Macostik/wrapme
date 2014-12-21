//
//  PGPhotoLibrary.h
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 4/17/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AssetsLibrary/AssetsLibrary.h"

@class CLLocation;

@interface ALAssetsLibrary (PGTools)

+ (instancetype)library;

+ (void)addDemoImages:(NSUInteger)count;

- (void)hasChanges:(void (^)(BOOL hasChanges))completion;

- (void)groups:(void(^)(NSArray *groups))finish failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (void)saveImage:(UIImage *)image toAlbum:(NSString *)albumName completion:(ALAssetsLibraryWriteImageCompletionBlock)completion failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (void)saveImage:(UIImage *)image toAlbum:(NSString *)albumName metadata:(NSDictionary *)metadata completion:(ALAssetsLibraryWriteImageCompletionBlock)completion failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (void)saveImageData:(NSData *)imageData toAlbum:(NSString *)albumName metadata:(NSDictionary *)metadata completion:(ALAssetsLibraryWriteImageCompletionBlock)completion failure:(ALAssetsLibraryAccessFailureBlock)failure;

@end

@interface ALAssetsGroup (PGTools)

@property (nonatomic, readonly) NSNumber *ID;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSURL* url;
@property (readonly, nonatomic) ALAssetsGroupType type;
@property (readonly, nonatomic) BOOL isSavedPhotos;

- (BOOL)isEqualToGroup:(ALAssetsGroup*)group;

- (void)assets:(void(^)(NSArray *assets))finish;

@end

@interface ALAsset (PGTools)

@property (nonatomic, readonly) NSString *ID;
@property (nonatomic, readonly) NSURL *url;

@property (nonatomic, readonly) NSDate* date;
@property (nonatomic, readonly) CLLocation* location;

@property (readonly, nonatomic) UIImage* image;

- (BOOL)isEqualToAsset:(ALAsset*)asset;

- (UIImage*)image:(CGFloat)maxSize;

@end
