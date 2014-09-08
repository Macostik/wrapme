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
    [self touch:[NSDate serverTime]];
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
    __block BOOL changed = NO;
    WLPicture* picture = self.picture;
    NSString* key = @"picture";
    void (^willChange) (void) = ^ {
        if (!changed) {
            [self willChangeValueForKey:key];
            changed = YES;
        }
    };
    if (!NSStringEqual(picture.large, large)) {
        willChange();
        picture.large = large;
    }
    if (!NSStringEqual(picture.medium, medium)) {
        willChange();
        picture.medium = medium;
    }
    if (!NSStringEqual(picture.small, small)) {
        willChange();
        picture.small = small;
    }
    if (changed) {
        [self setPrimitiveValue:picture forKey:key];
        [self didChangeValueForKey:key];
    }
}

@end
