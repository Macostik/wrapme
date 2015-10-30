//
//  WLEditPicture.h
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAsset.h"
#import "WLCommonEnums.h"

@class AVAssetExportSession;
@class PHAsset;

@interface WLEditPicture : WLAsset

@property (strong, nonatomic) NSString *comment;

@property (nonatomic) WLStillPictureMode mode;

@property (weak, nonatomic) WLImageCache *cache;

@property (nonatomic) BOOL saveToAlbum;

@property (strong, nonatomic) NSString* assetID;

@property (strong, nonatomic) NSDate* date;

@property (nonatomic) BOOL edited;

@property (nonatomic) BOOL selected;

@property (nonatomic) BOOL deleted;

@property (nonatomic) BOOL uploaded;

@property (weak, nonatomic) AVAssetExportSession *videoExportSession;

+ (instancetype)picture:(UIImage *)image completion:(WLObjectBlock)completion;

+ (instancetype)picture:(UIImage *)image cache:(WLImageCache*)cache completion:(WLObjectBlock)completion;

+ (instancetype)picture:(UIImage *)image mode:(WLStillPictureMode)mode completion:(WLObjectBlock)completion;

+ (instancetype)picture:(UIImage *)image mode:(WLStillPictureMode)mode cache:(WLImageCache*)cache completion:(WLObjectBlock)completion;

+ (instancetype)picture:(WLStillPictureMode)mode cache:(WLImageCache*)cache;

+ (instancetype)picture:(WLStillPictureMode)mode;

- (void)setImage:(UIImage *)image completion:(WLObjectBlock)completion;

- (void)setVideoAtPath:(NSString*)path completion:(WLObjectBlock)completion;

- (void)setVideoFromRecordAtPath:(NSString*)path completion:(WLObjectBlock)completion;

- (void)setVideoFromAsset:(PHAsset*)asset completion:(WLObjectBlock)completion;

- (WLAsset*)uploadablePicture:(BOOL)justUploaded;

- (void)saveToAssets;

- (void)saveToAssetsIfNeeded;

@end
