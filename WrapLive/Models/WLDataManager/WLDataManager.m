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

+ (void)wraps:(BOOL)refresh success:(WLDataManagerBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSInteger page = 1;
	if (refresh) {
		if ([[WLDataCache cache] containsWraps]) {
			[[WLDataCache cache] wraps:^(NSArray* wraps) {
				_wraps = wraps;
				if (success) {
					success(_wraps, YES, [wraps count] % WLAPIGeneralPageSize != 0);
				}
			}];
		}
	} else {
		page = ((_wraps.count + 1)/WLAPIGeneralPageSize + 1);
	}
	[[WLAPIManager instance] wrapsWithPage:page success:^(NSArray *object) {
		_wraps = refresh ? object : [(_wraps ? : @[]) arrayByAddingObjectsFromArray:object];
		[[WLDataCache cache] setWraps:_wraps completion:^(NSString *path) {
			if (success) {
				success(_wraps, NO, (object.count != WLAPIGeneralPageSize));
			}
		}];
	} failure:failure];
}

+ (void)wrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	if ([[WLDataCache cache] containsWrap:wrap]) {
		if (success) {
			success([wrap updateWithObject:[[WLDataCache cache] wrap:wrap]]);
		}
	}
	[[WLAPIManager instance] wrap:wrap success:^(WLWrap* _wrap) {
		[_wrap cache];
		if (success) {
			success(_wrap);
		}
	} failure:failure];
}

+ (void)candy:(WLCandy*)candy wrap:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	
	if ([[WLDataCache cache] containsCandy:candy]) {
		if (success) {
			success([candy updateWithObject:[[WLDataCache cache] candy:candy]]);
		}
	}
	
	[[WLAPIManager instance] candyInfo:candy forWrap:wrap success:^(id object) {
		[[WLDataCache cache] setCandy:object];
		if (success) {
			success(object);
		}
	} failure:failure];
}

+ (void)messages:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	if ([[WLDataCache cache] containsMessages:wrap]) {
		if (success) {
			success([[WLDataCache cache] messages:wrap]);
		}
	}
	[[WLAPIManager instance] chatMessages:wrap page:1 success:^(id object) {
		[[WLDataCache cache] setMessages:object wrap:wrap];
		if (success) {
			success(object);
		}
	} failure:failure];
}

@end
