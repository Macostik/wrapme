//
//  WLPicture.m
//  WrapLive
//
//  Created by Sergey Maximenko on 28.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPicture.h"

@implementation WLPicture

+ (JSONKeyMapper *)keyMapper {
	return [[JSONKeyMapper alloc] initWithDictionary:@{@"large_avatar_url":@"large",
													   @"medium_avatar_url":@"medium",
													   @"small_avatar_url":@"small",
													   @"thumb_avatar_url":@"thumbnail",
													   @"large_cover_url":@"large",
													   @"medium_cover_url":@"medium",
													   @"small_cover_url":@"small",
													   @"thumb_cover_url":@"thumbnail",}];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

@end
