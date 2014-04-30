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

+ (NSMutableDictionary*)mapping;

+ (NSMutableDictionary*)mergeMapping:(NSMutableDictionary*)_mapping withMapping:(NSDictionary*)mapping;

+ (instancetype)modelWithDictionary:(NSDictionary*)dict;

- (instancetype)updateWithDictionary:(NSDictionary*)dict;

- (instancetype)updateWithObject:(id)object;

@end

@interface NSObject (WLArchivingObject)

- (NSData*)archive;

- (void)archive:(void (^)(NSData* data))completion;

- (void)archiveToFileAtPath:(NSString*)path;

- (void)archiveToFileAtPath:(NSString*)path completion:(void (^)(void))completion;

+ (id)unarchive:(NSData*)data;

+ (void)unarchive:(NSData*)data completion:(void (^)(id object))completion;

+ (id)unarchiveFromFileAtPath:(NSString*)path;

+ (void)unarchiveFromFileAtPath:(NSString*)path completion:(void (^)(id object))completion;

@end

@interface JSONValueTransformer (NSDate)

- (NSDate*)NSDateFromNSString:(NSString*)string;

- (NSString*)JSONObjectFromNSDate:(NSDate*)date;

- (NSDate*)NSDateFromNSNumber:(NSNumber*)number;

@end
