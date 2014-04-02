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
		mapping = @{@"large":@[@"large_avatar_url",@"large_cover_url",@"large_image_attachment_url"],
					@"medium":@[@"medium_avatar_url",@"medium_cover_url",@"medium_image_attachment_url"],
					@"small":@[@"small_avatar_url",@"small_cover_url",@"small_image_attachment_url"],
					@"thumbnail":@[@"thumb_avatar_url",@"thumb_cover_url",@"thumb_image_attachment_url"]};
	}
	return mapping;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err
{
    self = [super init];
    if (self) {
        [[WLPicture mapping] enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSArray* obj, BOOL *stop) {
			for (NSString* urlKey in obj) {
				id object = [dict objectForKey:urlKey];
				if (object != nil) {
					[self setValue:object forKey:key];
				}
			}
		}];
    }
    return self;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

@end
