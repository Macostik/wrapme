//
//  WLEntry.m
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry+Extended.h"
#import "WLEntryManager.h"
#import "NSDate+Additions.h"
#import "NSString+Additions.h"
#import "WLServerTime.h"

@implementation WLEntry (Extended)

+ (instancetype)entry {
    WLEntry* entry = [self entry:GUID()];
    entry.createdAt = [NSDate serverTime];
    entry.updatedAt = entry.createdAt;
    return entry;
}

+ (NSOrderedSet*)API_entries:(NSArray*)array {
	return [self API_entries:array relatedEntry:nil];
}

+ (NSOrderedSet *)API_entries:(NSArray *)array relatedEntry:(id)relatedEntry {
	return [[self API_entries:array relatedEntry:relatedEntry container:[NSMutableOrderedSet orderedSet]] copy];
}

+ (NSMutableOrderedSet*)API_entries:(NSArray*)array relatedEntry:(id)relatedEntry container:(NSMutableOrderedSet*)container {
    if (!container) {
        container = [NSMutableOrderedSet orderedSet];
    }
    for (NSDictionary* dictionary in array) {
		WLEntry* entry = [self API_entry:dictionary relatedEntry:relatedEntry];
		if (entry) {
			[container addObject:entry];
		}
	}
    return container;
}

+ (instancetype)API_entry:(NSDictionary*)dictionary {
	return [self API_entry:dictionary relatedEntry:nil];
}

+ (instancetype)API_entry:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
	NSString* identifier = [self API_identifier:dictionary];
	return [[self entry:identifier] API_setup:dictionary relatedEntry:relatedEntry];
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return nil;
}

- (instancetype)API_setup:(NSDictionary *)dictionary {
	return [self API_setup:dictionary relatedEntry:nil];
}

- (instancetype)API_setup:(NSDictionary*)dictionary relatedEntry:(id)relatedEntry {
    self.updatedAt = [NSDate dateWithTimeIntervalSince1970:[dictionary doubleForKey:@"last_touched_at_in_epoch"]];
    self.createdAt = [NSDate dateWithTimeIntervalSince1970:[dictionary doubleForKey:@"contributed_at_in_epoch"]];
    self.identifier = [[self class] API_identifier:dictionary];
	return self;
}

- (BOOL)isEqualToEntry:(WLEntry *)entry {
	return self == entry;
}

- (NSComparisonResult)compare:(WLEntry *)entry {
    return [self.updatedAt compare:entry.updatedAt];
}

- (void)touch {
    [self touch:[NSDate serverTime]];
}

- (void)touch:(NSDate *)date {
    self.updatedAt = date;
    if (self.createdAt == nil) {
        self.createdAt = date;
    }
}

@end
