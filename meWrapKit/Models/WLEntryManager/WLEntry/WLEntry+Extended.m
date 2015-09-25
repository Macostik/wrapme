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

+ (instancetype)entry:(NSString *)identifier container:(WLEntry*)container {
    WLEntry* entry = [self entry:identifier];
    entry.container = container;
    return entry;
}

+ (NSSet*)API_entries:(NSArray*)array {
	return [self API_entries:array container:nil];
}

+ (NSSet*)API_entries:(NSArray*)array container:(id)container {
    if (array.count == 0) {
        return nil;
    }
    NSMutableSet *set = [NSMutableSet setWithCapacity:[array count]];
    for (NSDictionary* dictionary in array) {
		WLEntry* entry = [self API_entry:dictionary container:container];
		if (entry) {
            [set addObject:entry];
		}
	}
    return set;
}

+ (instancetype)API_entry:(NSDictionary*)dictionary {
	return [self API_entry:dictionary container:nil];
}

+ (instancetype)API_entry:(NSDictionary *)dictionary container:(id)container {
	NSString* identifier = [self API_identifier:dictionary];
	return [[self entry:identifier] API_setup:dictionary container:container];
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return nil;
}

- (instancetype)API_setup:(NSDictionary *)dictionary {
    if (dictionary) {
        return [self API_setup:dictionary container:nil];
    }
	return self;
}

- (instancetype)API_setup:(NSDictionary*)dictionary container:(id)container {
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
    if (self.container) {
        [self.container touch:date];
    }
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
