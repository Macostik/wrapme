//
//  WLPicture.h
//  WrapLive
//
//  Created by Sergey Maximenko on 28.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLArchivingObject.h"
#import "WLCommonEnums.h"
#import "WLAnimation.h"

@class WLImageCache;

@interface WLPicture : WLArchivingObject

@property (strong, nonatomic) NSString* original;
@property (strong, nonatomic) NSString* large;
@property (strong, nonatomic) NSString* medium;
@property (strong, nonatomic) NSString* small;

@property (strong, nonatomic) NSString *comment;

@property (nonatomic, strong) WLAnimation *animation;

+ (void)picture:(UIImage *)image completion:(WLObjectBlock)completion;

+ (void)picture:(UIImage *)image cache:(WLImageCache*)cache completion:(WLObjectBlock)completion;

+ (void)picture:(UIImage *)image mode:(WLStillPictureMode)mode completion:(WLObjectBlock)completion;

+ (void)picture:(UIImage *)image mode:(WLStillPictureMode)mode cache:(WLImageCache*)cache completion:(WLObjectBlock)completion;

- (NSString*)anyUrl;

- (WLPicture *)edit:(NSString*)original large:(NSString*)large medium:(NSString*)medium small:(NSString*)small;

- (void)fetch:(WLBlock)completion;

- (void)cacheForPicture:(WLPicture*)picture;

@end

@interface WLPicture (JSONValue)

+ (instancetype)pictureWithJSONValue:(NSData*)value;

- (NSData*)JSONValue;

@end

@interface WLPictureTransformer : NSValueTransformer

@end
