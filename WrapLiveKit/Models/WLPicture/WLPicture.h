//
//  WLPicture.h
//  moji
//
//  Created by Ravenpod on 28.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
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

@property (nonatomic, strong) WLAnimation *animation;

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
