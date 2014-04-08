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
	WLWrapDate* date = [self actualDate];
	NSMutableArray* candies = [NSMutableArray arrayWithArray:date.candies];
	[candies insertObject:candy atIndex:0];
	date.candies = [candies copy];
	self.updatedAt = [NSDate date];
}

- (NSArray *)latestCandies:(NSInteger)count {
	NSMutableArray* candies = [NSMutableArray array];
	for (WLWrapDate* date in self.dates) {
		if ([candies count] == 5) {
			break;
		}
		for (WLCandy* candy in date.candies) {
			[candies addObject:candy];
			if ([candies count] == 5) {
				break;
			}
		}
	}
	return [candies copy];
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
	NSArray* dates = [WLEntry entriesForDate:[NSDate date] inArray:self.dates];
	
	for (WLWrapDate* date in dates) {
		for (WLCandy* candy in date.candies) {
			if (candy.type == WLCandyTypeConversation) {
				return candy;
			}
		}
	}
	
	WLCandy* conversation = [WLCandy entry];
	conversation.type = WLCandyTypeConversation;
	[self addCandy:conversation];
	return conversation;
}

- (WLWrapDate *)actualDate {
	NSArray* dates = [WLEntry entriesForDate:[NSDate date] inArray:self.dates];
	
	WLWrapDate* date = [dates lastObject];
	
	if (!date) {
		date = [WLWrapDate entry];
		NSMutableArray* existingDates = [NSMutableArray arrayWithArray:self.dates];
		[existingDates insertObject:date atIndex:0];
		self.dates = [existingDates copy];
	}
	return date;
}

- (void) postNotificationForRequest:(BOOL)isNeedRequest {
	[[NSNotificationCenter defaultCenter] postNotificationName:WLWrapChangesNotification
														object:nil
													  userInfo:@{
																 @"wrap":self,
																 @"isNeedRequest":[NSNumber numberWithBool:isNeedRequest]
																 }];
}

@end
