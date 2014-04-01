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
#import "NSArray+Additions.h"
#import "WLUser.h"
#import "NSDate+Formatting.h"

@implementation WLWrap

+ (NSMutableArray *)dummyWraps {
	static NSMutableArray* _wraps = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSError* error = nil;
		_wraps = [[WLWrap arrayOfModelsFromDictionaries:[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WLDummyWraps" ofType:@"plist"]] error:&error] mutableCopy];
	});
	return _wraps;
}

+ (JSONKeyMapper *)keyMapper {
	return [[JSONKeyMapper alloc] initWithDictionary:@{@"wrap_uid":@"identifier",
													   @"created_at_in_epoch":@"createdAt",
													   @"updated_at_in_epoch":@"updatedAt"}];
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
