//
//  WLEntry.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"
#import "NSDate+Formatting.h"
#import "NSDate+Additions.h"

@implementation WLEntry

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"created_at_in_epoch":@"createdAt",
									@"updated_at_in_epoch":@"updatedAt"}];
}

+ (instancetype)entry {
	WLEntry* entry = [[self alloc] init];
	entry.createdAt = [NSDate date];
	entry.updatedAt = [NSDate date];
	return entry;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
	self = [super initWithDictionary:dict error:err];
	if (self) {
		self.picture = [WLPicture pictureWithDictionary:dict mapping:[[self class] pictureMapping]];
	}
	return self;
}

- (WLPicture *)picture {
	if (!_picture) {
		_picture = [[WLPicture alloc] init];
	}
	return _picture;
}

+ (NSDictionary *)pictureMapping {
	return nil;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

- (BOOL)isEqualToEntry:(WLEntry *)entry {
	return [self.identifier isEqualToString:entry.identifier];
}

+ (EqualityBlock)equalityBlock {
	static EqualityBlock _equalityBlock = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_equalityBlock = ^BOOL(id first, id second) {
			return [first isEqualToEntry:second];
		};
	});
	return _equalityBlock;
}

@end

@implementation NSArray (WLEntry)

- (NSArray *)entriesSortedByKeys:(NSArray *)keys ascending:(BOOL)ascending {
	return [self sortedArrayUsingDescriptors:[keys map:^id(id item) {
		return [NSSortDescriptor sortDescriptorWithKey:item ascending:ascending];
	}]];
}

- (NSArray *)entriesSortedByKey:(NSString *)key ascending:(BOOL)ascending {
	return [self entriesSortedByKeys:@[key] ascending:ascending];
}

- (NSArray *)entriesSortedByKey:(NSString *)key {
	return [self entriesSortedByKey:key ascending:NO];
}

- (NSArray *)entriesSortedByUpdatingDate {
	return [self entriesSortedByKey:@"updatedAt"];
}

- (NSArray *)entriesByAddingEntry:(WLEntry *)entry {
	return [self arrayByAddingUniqueObject:entry equality:[[entry class] equalityBlock]];
}

- (NSArray *)entriesByRemovingEntry:(WLEntry*)entry {
	return [self arrayByRemovingUniqueObject:entry equality:[[entry class] equalityBlock]];
}

- (BOOL)containsEntry:(WLEntry*)entry {
	return [self containsObject:entry byBlock:[[entry class] equalityBlock]];
}

- (NSArray *)entriesByAddingEntries:(NSArray*)entries {
	return [self arrayByAddingUniqueObjects:entries equality:[[[entries lastObject] class] equalityBlock]];
}

- (NSArray *)entriesByRemovingEntries:(NSArray*)entries {
	return [self arrayByRemovingUniqueObjects:entries equality:[[[entries lastObject] class] equalityBlock]];
}

- (NSArray *)entriesFrom:(NSDate *)from to:(NSDate *)to {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(updatedAt >= %@) AND (updatedAt <= %@)", from, to];
	return [self filteredArrayUsingPredicate:predicate];
}

- (NSArray *)entriesForDay:(NSDate *)date {
	return [self entriesFrom:[date beginOfDay] to:[date endOfDay]];
}

- (NSArray *)entriesForToday {
	return [self entriesForDay:[NSDate date]];
}

@end

@implementation NSMutableArray (WLEntry)

- (void)sortEntriesByKeys:(NSArray *)keys ascending:(BOOL)ascending {
	[self sortUsingDescriptors:[keys map:^id(id item) {
		return [NSSortDescriptor sortDescriptorWithKey:item ascending:ascending];
	}]];
}

- (void)sortEntriesByKey:(NSString*)key ascending:(BOOL)ascending {
	[self sortEntriesByKeys:@[key] ascending:ascending];
}

- (void)sortEntriesByKey:(NSString*)key {
	[self sortEntriesByKey:key ascending:NO];
}

- (void)sortEntriesByUpdatingDate {
	[self sortEntriesByKey:@"updatedAt"];
}

- (void)addEntry:(WLEntry*)entry {
	[self addUniqueObject:entry equality:[[entry class] equalityBlock]];
}

- (void)removeEntry:(WLEntry*)entry {
	[self removeUniqueObject:entry equality:[[entry class] equalityBlock]];
}

- (void)addEntries:(NSArray*)entries {
	[self addUniqueObjects:entries equality:[[[entries lastObject] class] equalityBlock]];
}

- (void)removeEntries:(NSArray *)entries {
	[self removeUniqueObjects:entries equality:[[[entries lastObject] class] equalityBlock]];
}

@end
