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

@implementation NSOrderedSet (WLEntry)

- (NSOrderedSet *)sortedEntries {
	return [self mutate:^(NSMutableOrderedSet *mutableCopy) {
        [mutableCopy sortEntries];
    }];
}

- (NSOrderedSet *)sortedEntriesAscending {
	return [self mutate:^(NSMutableOrderedSet *mutableCopy) {
        [mutableCopy sortEntriesAscending];
    }];
}

- (NSOrderedSet *)entriesFrom:(NSDate *)from to:(NSDate *)to {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(updatedAt >= %@) AND (updatedAt <= %@)", from, to];
	return [NSOrderedSet orderedSetWithArray:[[self array] filteredArrayUsingPredicate:predicate]];
}

- (NSOrderedSet *)entriesForDay:(NSDate *)date {
	return [self entriesFrom:[date beginOfDay] to:[date endOfDay]];
}

- (NSOrderedSet *)entriesForToday {
	return [self entriesForDay:[NSDate serverTime]];
}

@end

@implementation NSMutableOrderedSet (WLEntry)

NSComparator comparatorByUpdatedAtAscending = ^NSComparisonResult(WLEntry* obj1, WLEntry* obj2) {
    return [obj1.updatedAt compare:obj2.updatedAt];
};

NSComparator comparatorByUpdatedAtDescending = ^NSComparisonResult(WLEntry* obj1, WLEntry* obj2) {
    return [obj2.updatedAt compare:obj1.updatedAt];
};

NSComparator comparatorByCreatedAtAscending = ^NSComparisonResult(WLEntry* obj1, WLEntry* obj2) {
    return [obj1.createdAt compare:obj2.createdAt];
};

NSComparator comparatorByCreatedAtDescending = ^NSComparisonResult(WLEntry* obj1, WLEntry* obj2) {
    return [obj2.createdAt compare:obj1.createdAt];
};

- (void)sortEntries {
    [self sortWithOptions:NSSortStable usingComparator:comparatorByUpdatedAtDescending];
}

- (void)sortEntriesAscending {
	[self sortWithOptions:NSSortStable usingComparator:comparatorByUpdatedAtAscending];
}

- (void)sortEntriesByCreationAscending {
    [self sortWithOptions:NSSortStable usingComparator:comparatorByCreatedAtAscending];
}

@end
