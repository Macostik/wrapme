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

@property (nonatomic) BOOL isAsset;

@property (nonatomic) BOOL edited;

@property (nonatomic) BOOL selected;

@property (nonatomic) BOOL deleted;

+ (instancetype)picture:(UIImage *)image completion:(WLObjectBlock)completion;

+ (instancetype)picture:(UIImage *)image cache:(WLImageCache*)cache completion:(WLObjectBlock)completion;

+ (instancetype)picture:(UIImage *)image mode:(WLStillPictureMode)mode completion:(WLObjectBlock)completion;

+ (instancetype)picture:(UIImage *)image mode:(WLStillPictureMode)mode cache:(WLImageCache*)cache completion:(WLObjectBlock)completion;

- (void)setImage:(UIImage *)image completion:(WLObjectBlock)completion;

- (WLPicture*)uploadablePictureWithAnimation:(BOOL)withAnimation;

@end
