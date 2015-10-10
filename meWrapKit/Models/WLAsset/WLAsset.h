//
//  WLAsset.h
//  meWrap
//
//  Created by Ravenpod on 28.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLArchivingObject.h"
#import "DefinedBlocks.h"

@class WLImageCache;

@interface WLAsset : WLArchivingObject

@property (nonatomic) NSInteger type;

@property (strong, nonatomic) NSString* original;
@property (strong, nonatomic) NSString* large;
@property (strong, nonatomic) NSString* medium;
@property (strong, nonatomic) NSString* small;

@property (nonatomic) BOOL justUploaded;

- (NSString*)anyUrl;

- (void)fetch:(WLBlock)completion;

- (void)cacheForPicture:(WLAsset*)picture;

@end

@interface WLAsset (JSONValue)

+ (instancetype)pictureWithJSONValue:(NSData*)value;

- (NSData*)JSONValue;

@end

@interface WLAssetTransformer : NSValueTransformer

@end
