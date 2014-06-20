//
//  WLDataManager.m
//  WrapLive
//
//  Created by Sergey Maximenko on 29.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLDataManager.h"

@implementation WLDataManager

+ (void)wraps:(BOOL)refresh success:(WLDataManagerBlock)success failure:(WLFailureBlock)failure {
	NSInteger page = 1;
    WLUser* user = [WLUser currentUser];
	if (!refresh) {
        page = ((user.wraps.count + 1)/WLAPIGeneralPageSize + 1);
	}
	[[WLAPIManager instance] wraps:page success:^(NSOrderedSet *object) {
        user.wraps = [NSOrderedSet orderedSetWithBlock:^(NSMutableOrderedSet *set) {
            [set unionOrderedSet:user.wraps];
            [set unionOrderedSet:object];
            [set sortEntries];
        }];
		[[WLEntryManager manager] save];
        if (success) {
            success(user.wraps, (object.count != WLAPIGeneralPageSize));
        }
	} failure:failure];
}

+ (void)wrap:(WLWrap *)wrap success:(WLDataManagerBlock)success failure:(WLFailureBlock)failure {
//    NSUInteger count = [wrap.candies count];
	[wrap fetch:^(WLWrap *wrap) {
        [[WLEntryManager manager] save];
		if (success) {
			success(wrap, !wrap.candies.nonempty);
		}
	} failure:failure];
}

+ (void)candy:(WLCandy*)candy success:(WLDataManagerBlock)success failure:(WLFailureBlock)failure {
	[candy fetch:^(WLCandy *candy) {
        [[WLEntryManager manager] save];
		if (success) {
			success(candy, YES);
		}
	} failure:failure];
}

+ (void)messages:(WLWrap *)wrap success:(WLDataManagerBlock)success failure:(WLFailureBlock)failure {
	[wrap messages:1 success:^(NSArray *array) {
        [[WLEntryManager manager] save];
		if (success) {
			success(array, YES);
		}
	} failure:failure];
}

@end
