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
	entry.contributor = [WLSession user];
	return entry;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dict error:err];
    if (self) {
        self.contributor.name = [dict stringForKey:@"contributor_name"];
		self.contributor.picture = [[WLPicture alloc] initWithDictionary:dict error:NULL];
    }
    return self;
}

- (WLUser *)contributor {
	if (!_contributor) {
		_contributor = [[WLUser alloc] init];
	}
	return _contributor;
}

@end
