//
//  WLWrapDay.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/27/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapDate.h"

@implementation WLWrapDate

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"date_in_epoch":@"updatedAt"}];
}

- (NSArray<WLCandy> *)candies {
	if (!_candies) {
		_candies = (id)[NSArray array];
	}
	return _candies;
}

@end
