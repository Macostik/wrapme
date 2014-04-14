//
//  WLWrapDay.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/27/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapDate.h"
#import "WLCandy.h"
#import "NSArray+Additions.h"

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

- (void)addCandy:(WLCandy *)candy {
	NSMutableArray* candies = [NSMutableArray arrayWithArray:self.candies];
	if (candy.type == WLCandyTypeChatMessage) {
		[candies removeObject:[candies selectObject:^BOOL(WLCandy* candy) {
			return candy.type == WLCandyTypeChatMessage;
		}]];
	}
	[candies insertObject:candy atIndex:0];
	self.candies = [candies copy];
}

- (void)removeCandy:(WLCandy *)candy {
	self.candies = (id)[self.candies arrayByRemovingObject:candy];
}

@end
