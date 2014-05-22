//
//  WLDataManager.m
//  WrapLive
//
//  Created by Sergey Maximenko on 29.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLDataManager.h"
#import "WLDataCache.h"

@implementation WLDataManager

static NSArray* _wraps = nil;

+ (void)wraps:(BOOL)refresh success:(WLDataManagerBlock)success failure:(WLFailureBlock)failure {
	NSInteger page = 1;
	if (refresh && [[WLDataCache cache] containsWraps] && success) {
		[[WLDataCache cache] wraps:^(NSArray* wraps) {
			_wraps = wraps;
			success(_wraps, YES, [wraps count] % WLAPIGeneralPageSize != 0);
		}];
	} else {
		page = ((_wraps.count + 1)/WLAPIGeneralPageSize + 1);
	}
	[[WLAPIManager instance] wraps:page success:^(NSArray *object) {
		_wraps = refresh ? object : [(_wraps ? : @[]) entriesByAddingEntries:object];
		[[WLDataCache cache] setWraps:_wraps completion:^(NSString *path) {
			if (success) {
				success(_wraps, NO, (object.count != WLAPIGeneralPageSize));
			}
		}];
	} failure:failure];
}

+ (void)wrap:(WLWrap *)wrap success:(WLDataManagerBlock)success failure:(WLFailureBlock)failure {
	if ([[WLDataCache cache] containsWrap:wrap] && success) {
		success([wrap updateWithObject:[[WLDataCache cache] wrap:wrap]], YES, YES);
	}
	[wrap fetch:^(WLWrap *wrap) {
		[wrap cache];
		if (success) {
			success(wrap, NO, ([wrap.dates count] != WLAPIGeneralPageSize));
		}
	} failure:failure];
}

+ (void)candy:(WLCandy*)candy wrap:(WLWrap*)wrap success:(WLDataManagerBlock)success failure:(WLFailureBlock)failure {
	
	if ([[WLDataCache cache] containsCandy:candy] && success) {
		success([candy updateWithObject:[[WLDataCache cache] candy:candy]], YES, YES);
	}
	
	[candy fetch:wrap success:^(WLCandy *candy) {
		[candy cache];
		if (success) {
			success(candy, NO, YES);
		}
	} failure:failure];
}

+ (void)messages:(WLWrap *)wrap success:(WLDataManagerBlock)success failure:(WLFailureBlock)failure {
	if ([[WLDataCache cache] containsMessages:wrap] && success) {
		success([[WLDataCache cache] messages:wrap], YES, YES);
	}
	[wrap messages:1 success:^(NSArray *array) {
		[[WLDataCache cache] setMessages:array wrap:wrap];
		if (success) {
			success(array, NO, YES);
		}
	} failure:failure];
}

@end
