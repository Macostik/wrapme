//
//  WLArchivingObject.h
//  WrapLive
//
//  Created by Sergey Maximenko on 21.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "NSDictionary+Extended.h"

@interface WLArchivingObject : JSONModel <NSCoding, NSCopying>

- (NSData*)data;

- (void)data:(void (^)(NSData* data))completion;

+ (id)objectWithData:(NSData*)data;

+ (void)objectWithData:(NSData*)data completion:(void (^)(id object))completion;

+ (NSMutableDictionary*)mapping;

+ (instancetype)modelWithDictionary:(NSDictionary*)dict;

- (instancetype)updateWithDictionary:(NSDictionary*)dict;

- (instancetype)updateWithObject:(id)object;

@end

@interface JSONValueTransformer (NSDate)

- (NSDate*)NSDateFromNSString:(NSString*)string;

- (NSString*)JSONObjectFromNSDate:(NSDate*)date;

- (NSDate*)NSDateFromNSNumber:(NSNumber*)number;

@end
