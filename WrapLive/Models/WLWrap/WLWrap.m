//
//  WLWrap.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrap.h"
#import "WLCandy.h"
#import "WLSession.h"
#import "NSArray+Additions.h"
#import "WLUser.h"
#import "NSDate+Formatting.h"
#import "WLWrapDate.h"
#import "WLWrapBroadcaster.h"
#import "NSString+Additions.h"

@implementation WLWrap

+ (NSDictionary*)pictureMapping {
	return @{@"large":@[@"large_cover_url"],
			 @"medium":@[@"medium_cover_url"],
			 @"small":@[@"small_cover_url"]};
}

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"wrap_uid":@"identifier"}];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dict error:err];
    if (self) {
        self.contributor = [self.contributors selectObject:^BOOL(WLUser* contributor) {
			return contributor.isCreator;
		}];
    }
    return self;
}

- (void)addCandy:(WLCandy *)candy {
	WLWrapDate* date = [self actualDate];
	[date addCandy:candy];
	self.updatedAt = [NSDate date];
	[self broadcastChange];
	[candy broadcastCreation];
}

- (void)addCandies:(NSArray *)candies {
	WLWrapDate* date = [self actualDate];
	for (WLCandy* candy in candies) {
		[date addCandy:candy];
	}
	self.updatedAt = [NSDate date];
	[self broadcastChange];
}

- (void)removeCandy:(WLCandy *)candy {
	for (WLWrapDate* date in self.dates) {
		for (WLCandy* _candy in date.candies) {
			if ([_candy isEqualToEntry:candy]) {
				[date removeCandy:_candy];
				[self broadcastChange];
				[candy broadcastRemoving];
			}
		}
	}
}

- (NSString *)contributorNames {
	if (!_contributorNames) {
		NSMutableArray* contributors = [self.contributors mutableCopy];
		[contributors exchangeObjectAtIndex:[contributors indexOfObjectPassingTest:^BOOL(WLUser* contributor, NSUInteger idx, BOOL *stop) {
			return [contributor isCurrentUser];
		}] withObjectAtIndex:0];
		_contributorNames = [[contributors map:^id(WLUser* contributor) {
			return [contributor isCurrentUser] ? @"You" : contributor.name;
		}] componentsJoinedByString:@", "];
	}
	return _contributorNames;
}

- (instancetype)updateWithObject:(id)object {
	self.contributorNames = nil;
	WLWrap* wrap = [super updateWithObject:object];
	[wrap broadcastChange];
	return wrap;
}

- (void)setContributors:(NSArray<WLUser> *)contributors {
	_contributors = contributors;
	self.contributorNames = nil;
}

- (WLWrapDate *)actualDate {
	NSArray* dates = [self.dates entriesForToday];
	WLWrapDate* date = [dates lastObject];
	if (!date) {
		date = [WLWrapDate entry];
		NSMutableArray* existingDates = [NSMutableArray arrayWithArray:self.dates];
		[existingDates insertObject:date atIndex:0];
		self.dates = [existingDates copy];
	}
	return date;
}

- (BOOL)isEqualToEntry:(WLWrap *)wrap {
	if (self.identifier.nonempty && wrap.identifier.nonempty) {
		return [super isEqualToEntry:wrap];
	}
	return [self.picture.large isEqualToString:wrap.picture.large];
}

- (NSArray *)candiesOfType:(NSInteger)type maximumCount:(NSUInteger)maximumCount {
	NSMutableArray* candies = [NSMutableArray array];
	for (WLWrapDate* date in self.dates) {
		if (maximumCount > 0) {
			[candies addObjectsFromArray:[date candiesOfType:type maximumCount:maximumCount - [candies count]]];
			if ([candies count] >= maximumCount) {
				return [candies copy];
			}
		} else {
			[candies addObjectsFromArray:[date candiesOfType:type maximumCount:0]];
		}
	}
	return [candies copy];
}

- (NSArray *)candies:(NSUInteger)maximumCount {
	return [self candiesOfType:0 maximumCount:maximumCount];
}

- (NSArray*)candies {
	return [self candies:0];
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
