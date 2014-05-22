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
	return [self mergeMapping:[super mapping] withMapping:@{@"date_in_epoch":@"updatedAt"}];
}

- (NSArray<WLCandy> *)candies {
	if (!_candies) {
		_candies = (id)[NSArray array];
	}
	return _candies;
}

- (void)addCandy:(WLCandy *)candy {
	[self addCandy:candy replaceMessage:YES];
}

- (void)addCandy:(WLCandy *)candy replaceMessage:(BOOL)replaceMessage {
	NSMutableArray* candies = [NSMutableArray arrayWithArray:self.candies];
	if (candy.type == WLCandyTypeChatMessage && replaceMessage) {
		NSArray* messages = [candies selectObjects:^BOOL(WLCandy* candy) {
			return candy.type == WLCandyTypeChatMessage;
		}];
		if (messages.nonempty) {
			[candies removeObjectsInArray:messages];
		}
	}
	[candies insertFirstEntry:candy];
	self.candies = [candies copy];
}

- (void)removeCandy:(WLCandy *)candy {
	self.candies = (id)[self.candies arrayByRemovingObject:candy];
}

- (NSArray *)candiesOfType:(NSInteger)type maximumCount:(NSUInteger)maximumCount {
	NSMutableArray* candies = [NSMutableArray array];
	for (WLCandy* candy in self.candies) {
		if (type == 0 || candy.type == type) {
			[candies addObject:candy];
			if (maximumCount > 0 && [candies count] == maximumCount) {
				return [candies copy];
			}
		}
	}
	return [candies copy];
}

- (NSArray *)candies:(NSUInteger)maximumCount {
	return [self candiesOfType:0 maximumCount:maximumCount];
}

- (NSArray*)images:(NSUInteger)maximumCount {
	return [self candiesOfType:WLCandyTypeImage maximumCount:maximumCount];
}

- (NSArray*)messages:(NSUInteger)maximumCount {
	return [self candiesOfType:WLCandyTypeChatMessage maximumCount:maximumCount];
}

- (NSArray*)images {
	return [self images:0];
}

- (NSArray*)messages {
	return [self messages:0];
}

@end
