//
//  WLPicture.h
//  WrapLive
//
//  Created by Sergey Maximenko on 28.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLArchivingObject.h"

@class WLImageCache;

@interface WLPicture : WLArchivingObject

@property (strong, nonatomic) NSString* large;
@property (strong, nonatomic) NSString* medium;
@property (strong, nonatomic) NSString* small;

@property (nonatomic) BOOL animate;

+ (void)picture:(UIImage *)image completion:(WLObjectBlock)completion;

+ (void)picture:(UIImage *)image cache:(WLImageCache*)cache completion:(WLObjectBlock)completion;

- (NSString*)anyUrl;

- (BOOL)edit:(NSString*)large medium:(NSString*)medium small:(NSString*)small;

- (void)fetch:(WLBlock)completion;

@end

@interface WLPicture (JSONValue)

+ (instancetype)pictureWithJSONValue:(NSData*)value;

- (NSData*)JSONValue;

@end

@interface WLPictureTransformer : NSValueTransformer

@end
