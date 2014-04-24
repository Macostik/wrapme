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
		mapping = @{@"large":@[@"large_avatar_url",
							   @"large_cover_url",
							   @"large_image_attachment_url",
							   @"contributor_large_avatar_url"],
					@"medium":@[@"medium_avatar_url",
								@"medium_cover_url",
								@"medium_image_attachment_url",
								@"contributor_medium_avatar_url"],
					@"small":@[@"small_avatar_url",
							   @"small_cover_url",
							   @"small_image_attachment_url",
							   @"contributor_small_avatar_url"]};
	}
	return mapping;
}

+ (instancetype)pictureWithDictionary:(NSDictionary *)dict mapping:(NSDictionary *)mapping {
	WLPicture* picture = [[self alloc] init];
	[WLPicture mapPicture:picture withMapping:mapping ? : [WLPicture mapping] dictionary:dict];
	return picture;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super init];
    if (self) {
		[WLPicture mapPicture:self withMapping:[WLPicture mapping] dictionary:dict];
    }
    return self;
}

+ (void)mapPicture:(WLPicture*)picture withMapping:(NSDictionary*)mapping dictionary:(NSDictionary*)dict {
	[mapping enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSArray* obj, BOOL *stop) {
		for (NSString* urlKey in obj) {
			id object = [dict objectForKey:urlKey];
			if (object != nil) {
				[picture setValue:object forKey:key];
			}
		}
	}];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

@end
