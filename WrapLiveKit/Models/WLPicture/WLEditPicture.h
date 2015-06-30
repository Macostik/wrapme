//
//  WLEditPicture.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WrapLiveKit/WLPicture.h>

@interface WLEditPicture : WLPicture

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

+ (instancetype)picture:(UIImage *)image completion:(WLObjectBlock)completion;

+ (instancetype)picture:(UIImage *)image cache:(WLImageCache*)cache completion:(WLObjectBlock)completion;

+ (instancetype)picture:(UIImage *)image mode:(WLStillPictureMode)mode completion:(WLObjectBlock)completion;

+ (instancetype)picture:(UIImage *)image mode:(WLStillPictureMode)mode cache:(WLImageCache*)cache completion:(WLObjectBlock)completion;

+ (instancetype)picture:(WLStillPictureMode)mode cache:(WLImageCache*)cache;

+ (instancetype)picture:(WLStillPictureMode)mode;

- (void)setImage:(UIImage *)image completion:(WLObjectBlock)completion;

- (WLPicture*)uploadablePictureWithAnimation:(BOOL)withAnimation;

- (void)saveToAssets;

- (void)saveToAssetsIfNeeded;

@end
