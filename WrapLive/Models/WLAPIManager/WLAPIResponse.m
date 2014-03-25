//
//  WLAPIResponse.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAPIResponse.h"

@implementation WLAPIResponse

+ (JSONKeyMapper *)keyMapper {
	return [[JSONKeyMapper alloc] initWithDictionary:@{@"return_code":@"code"}];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

@end
