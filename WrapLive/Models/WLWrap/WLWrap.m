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

@implementation WLWrap

+ (NSDictionary*)pictureMapping {
	return @{@"large":@[@"large_cover_url"],
			 @"medium":@[@"medium_cover_url"],
			 @"small":@[@"small_cover_url"],
			 @"thumbnail":@[@"thumb_cover_url"]};
}

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"wrap_uid":@"identifier"}];
}

- (void)addCandy:(WLCandy *)candy {
	NSMutableArray* candies = [NSMutableArray arrayWithArray:self.candies];
	[candies insertObject:candy atIndex:0];
	self.candies = [candies copy];
	self.updatedAt = [NSDate date];
}

- (void)contributorNames:(void (^)(NSString *))completion {
	__weak typeof(self)weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString* names = [[weakSelf.contributors map:^id(WLUser* contributor) {
			return contributor.name;
		}] componentsJoinedByString:@", "];
        dispatch_async(dispatch_get_main_queue(), ^{
			completion(names);
        });
    });
}

- (WLCandy *)actualConversation {
	NSArray* candies = [self candiesForDate:[NSDate date]];
	for (WLCandy* candy in candies) {
		if ([candy.type isEqualToString:WLCandyTypeConversation]) {
			return candy;
		}
	}
	
	WLCandy* conversation = [WLCandy entry];
	conversation.type = WLCandyTypeConversation;
	[self addCandy:conversation];
	return conversation;
}

- (NSArray *)candiesForDate:(NSDate *)date {
	return [WLWrap candiesForDate:date inArray:self.candies];
}

+ (NSArray *)candiesForDate:(NSDate *)date inArray:(NSArray *)candies {
	NSDate* startDate = [date beginOfDay];
	NSDate* endDate = [date endOfDay];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(updatedAt >= %@) AND (updatedAt <= %@)", startDate, endDate];
	return [candies filteredArrayUsingPredicate:predicate];
}

@end
