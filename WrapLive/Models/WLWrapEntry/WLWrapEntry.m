//
//  WLWrapEntry.m
//  WrapLive
//
//  Created by Sergey Maximenko on 01.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEntry.h"
#import "WLSession.h"

@implementation WLWrapEntry

+ (NSMutableDictionary *)mapping {
	NSMutableDictionary* mapping = [super mapping];
	[mapping addEntriesFromDictionary:@{@"contributed_at_in_epoch":@"contributedAt"}];
	return mapping;
}

+ (instancetype)entry {
	WLWrapEntry* entry = [super entry];
	entry.author = [WLSession user];
	return entry;
}

@end
