//
//  WLWrapEntry.m
//  WrapLive
//
//  Created by Sergey Maximenko on 01.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEntry.h"
#import "WLSession.h"
#import "WLUser.h"

@implementation WLWrapEntry

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"contributed_at_in_epoch":@"contributedAt"}];
}

+ (instancetype)entry {
	WLWrapEntry* entry = [super entry];
	entry.author = [WLSession user];
	return entry;
}

- (WLUser *)author {
	if (!_author) {
		_author = [[WLUser alloc] init];
	}
	return _author;
}

@end
