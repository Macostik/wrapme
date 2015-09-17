//
//  WLPicture.h
//  meWrap
//
//  Created by Ravenpod on 28.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLArchivingObject.h"
#import "DefinedBlocks.h"

@class WLImageCache;

@interface WLPicture : WLArchivingObject

@property (strong, nonatomic) NSString* original;
@property (strong, nonatomic) NSString* large;
@property (strong, nonatomic) NSString* medium;
@property (strong, nonatomic) NSString* small;

@property (nonatomic) BOOL justUploaded;

- (NSString*)anyUrl;

- (WLPicture *)editWithCandyDictionary:(NSDictionary*)dictionary;

- (WLPicture *)editWithUserDictionary:(NSDictionary*)dictionary;

- (WLPicture *)editWithContributorDictionary:(NSDictionary *)dictionary;

- (void)fetch:(WLBlock)completion;

- (void)cacheForPicture:(WLPicture*)picture;

@end

@interface WLPicture (JSONValue)

+ (instancetype)pictureWithJSONValue:(NSData*)value;

- (NSData*)JSONValue;

@end

@interface WLPictureTransformer : NSValueTransformer

@end
