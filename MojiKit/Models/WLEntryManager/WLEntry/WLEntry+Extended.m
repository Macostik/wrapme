//
//  WLEntry.m
//  CoreData1
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntry+Extended.h"
#import "WLEntryManager.h"
#import "NSDate+Additions.h"
#import "NSString+Additions.h"
#import "WLAPIRequest.h"

@implementation WLEntry (Extended)

+ (instancetype)entry {
    WLEntry* entry = [self entry:GUID()];
    entry.createdAt = [NSDate now];
    entry.updatedAt = entry.createdAt;
    return entry;
}

+ (instancetype)entry:(NSString *)identifier containingEntry:(WLEntry*)containingEntry {
    WLEntry* entry = [self entry:identifier];
    entry.containingEntry = containingEntry;
    return entry;
}

+ (NSSet*)API_entries:(NSArray*)array {
	return [self API_entries:array relatedEntry:nil];
}

+ (NSSet *)API_entries:(NSArray *)array relatedEntry:(id)relatedEntry {
	return [self API_entries:array relatedEntry:relatedEntry container:[NSMutableSet setWithCapacity:[array count]]];
}

+ (NSSet*)API_entries:(NSArray*)array relatedEntry:(id)relatedEntry container:(NSMutableSet*)container {
    if (!container) {
        container = [NSMutableSet setWithCapacity:[array count]];
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
    if (dictionary) {
        return [self API_setup:dictionary relatedEntry:nil];
    }
	return self;
}

- (instancetype)API_setup:(NSDictionary*)dictionary relatedEntry:(id)relatedEntry {
    NSDate* createdAt = [dictionary timestampDateForKey:WLContributedAtKey];
    if (!NSDateEqual(self.createdAt, createdAt)) self.createdAt = createdAt;
    NSDate* updatedAt = [dictionary timestampDateForKey:WLLastTouchedAtKey];
    if (updatedAt) {
        if (!NSDateEqual(self.updatedAt, updatedAt)) self.updatedAt = updatedAt;
    } else {
        if (!NSDateEqual(self.updatedAt, createdAt)) self.updatedAt = createdAt;
    }
    NSString* identifier = [[self class] API_identifier:dictionary];
    if (!NSStringEqual(self.identifier, identifier)) self.identifier = identifier;
	return self;
}

- (BOOL)isEqualToEntry:(WLEntry *)entry {
	return self == entry;
}

- (NSComparisonResult)compare:(WLEntry *)entry {
    return [self.updatedAt compare:entry.updatedAt];
}

- (void)touch {
    [self touch:[NSDate now]];
}

- (void)touch:(NSDate *)date {
    self.updatedAt = date;
    if (self.createdAt == nil) {
        self.createdAt = date;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@", [self class], self.identifier];
}

- (void)editPicture:(WLPicture*)editedPicture {
    if (self.picture != editedPicture) {
        self.picture = editedPicture;
    }
}

- (void)markAsRead {
    if (self.valid && self.unread) self.unread = NO;
}

- (void)markAsUnread {
    if (self.valid && !self.unread) self.unread = YES;
}

@end
