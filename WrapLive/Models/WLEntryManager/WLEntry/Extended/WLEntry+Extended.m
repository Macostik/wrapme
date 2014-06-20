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

@implementation WLEntry (Extended)

+ (instancetype)entry {
    WLEntry* entry = [self entry:GUID() create:YES];
    entry.createdAt = [NSDate date];
    entry.updatedAt = [NSDate date];
    return entry;
}

+ (NSOrderedSet*)API_entries:(NSArray*)array {
	return [self API_entries:array relatedEntry:nil];
}

+ (NSOrderedSet *)API_entries:(NSArray *)array relatedEntry:(id)relatedEntry {
	NSMutableOrderedSet* entries = [NSMutableOrderedSet orderedSet];
	for (NSDictionary* dictionary in array) {
		WLEntry* entry = [self API_entry:dictionary relatedEntry:relatedEntry];
		if (entry) {
			[entries addObject:entry];
		}
	}
	return [entries copy];
}

+ (instancetype)API_entry:(NSDictionary*)dictionary {
	return [self API_entry:dictionary relatedEntry:nil];
}

+ (instancetype)API_entry:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
	NSString* identifier = [self API_identifier:dictionary];
	return [[self entry:identifier create:YES] API_setup:dictionary relatedEntry:relatedEntry];
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
    self.updatedAt = [NSDate date];
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
	return [self entriesForDay:[NSDate date]];
}

@end

@implementation NSMutableOrderedSet (WLEntry)

- (void)sortEntries {
    static NSArray* descriptors = nil;
    if (!descriptors) {
        descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]];
    }
	[self sortUsingDescriptors:descriptors];
}

- (void)sortEntriesAscending {
    static NSArray* descriptors = nil;
    if (!descriptors) {
        descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:YES]];
    }
	[self sortUsingDescriptors:descriptors];
}

@end
