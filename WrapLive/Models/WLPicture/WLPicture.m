//
//  WLPicture.m
//  WrapLive
//
//  Created by Sergey Maximenko on 28.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPicture.h"

@implementation WLPicture

static NSDictionary* mapping = nil;

+ (NSDictionary*)mapping {
	if (!mapping) {
		mapping = @{@"large_avatar_url":@"large",
					@"medium_avatar_url":@"medium",
					@"small_avatar_url":@"small",
					@"thumb_avatar_url":@"thumbnail",
					@"large_cover_url":@"large",
					@"medium_cover_url":@"medium",
					@"small_cover_url":@"small",
					@"thumb_cover_url":@"thumbnail"};
	}
	return mapping;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err
{
    self = [super init];
    if (self) {
		NSDictionary* mapping = [WLPicture mapping];
        [mapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			id object = [dict objectForKey:key];
			if (object != nil) {
				[self setValue:object forKey:[mapping objectForKey:key]];
			}
		}];
    }
    return self;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

- (NSString *)large {
	return @"http://placeimg.com/100/100/any";
}

@end
