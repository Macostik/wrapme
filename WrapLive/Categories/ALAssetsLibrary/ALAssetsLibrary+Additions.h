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

- (void)enumerateGroups:(void(^)(ALAssetsGroup *group))finish failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (void)groups:(void(^)(NSArray *groups))finish failure:(ALAssetsLibraryAccessFailureBlock)failure;
- (void)assets:(void(^)(NSArray *assets))finish failure:(ALAssetsLibraryAccessFailureBlock)failure;
- (void)groups:(void(^)(NSArray *groups))groupsBlock assets:(void(^)(NSArray *assets))assetsBlock failure:(ALAssetsLibraryAccessFailureBlock)failure;
- (void)group:(void(^)(ALAssetsGroup *group))groupBlock asset:(void(^)(ALAsset *asset))assetBlock finish:(void (^)(void))finish failure:(ALAssetsLibraryAccessFailureBlock)failure;
- (void)groupWithUrl:(NSURL*)url finish:(void(^)(ALAssetsGroup *group))finish failure:(ALAssetsLibraryAccessFailureBlock)failure;

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

- (BOOL)isEqualToAsset:(ALAsset*)asset;

- (UIImage*)image:(CGFloat)maxSize;

@end
