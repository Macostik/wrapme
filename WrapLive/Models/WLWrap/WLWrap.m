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

- (void)broadcastChange {
	[[WLWrapBroadcaster broadcaster] broadcastChange:self];
}

- (void)broadcastCreation {
	[[WLWrapBroadcaster broadcaster] broadcastCreation:self];
}

- (BOOL)isEqualToWrap:(WLWrap *)wrap {
	return [self.identifier isEqualToString:wrap.identifier];
}

@end
