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
#import "WLAPIRequest.h"

@implementation WLEntry (Extended)

@dynamic containingEntry;

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

+ (NSMutableOrderedSet*)API_entries:(NSArray*)array {
	return [self API_entries:array relatedEntry:nil];
}

+ (NSMutableOrderedSet *)API_entries:(NSArray *)array relatedEntry:(id)relatedEntry {
	return [[self API_entries:array relatedEntry:relatedEntry container:[NSMutableOrderedSet orderedSetWithCapacity:[array count]]] copy];
}

+ (NSMutableOrderedSet*)API_entries:(NSArray*)array relatedEntry:(id)relatedEntry container:(NSMutableOrderedSet*)container {
    if (!container) {
        container = [NSMutableOrderedSet orderedSetWithCapacity:[array count]];
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
    NSDate* updatedAt = [dictionary timestampDateForKey:WLLastTouchedAtKey];
    if (!NSDateEqual(self.updatedAt, updatedAt)) self.updatedAt = updatedAt;
    NSDate* createdAt = [dictionary timestampDateForKey:WLContributedAtKey];
    if (!NSDateEqual(self.createdAt, createdAt)) self.createdAt = createdAt;
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

- (void)editPicture:(NSString*)large medium:(NSString*)medium small:(NSString*)small {
    WLPicture* picture = self.picture;
    if ([picture edit:large medium:medium small:small]) {
        self.picture = [picture copy];
    }
}

- (WLEntry*)containingEntry {
    return nil;
}

- (void)setContainingEntry:(WLEntry *)containingEntry {
    
}

@end
