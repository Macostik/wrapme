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

+ (NSArray *)entriesForDate:(NSDate *)date inArray:(NSArray *)entries {
	NSDate* startDate = [date beginOfDay];
	NSDate* endDate = [date endOfDay];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(updatedAt >= %@) AND (updatedAt <= %@)", startDate, endDate];
	return [entries filteredArrayUsingPredicate:predicate];
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

@implementation NSArray (WLEntrySorting)

+ (NSArray*)modifiedDescriptors {
	static NSArray* descriptors = nil;
	if (!descriptors) {
		descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]];
	}
	return descriptors;
}

- (NSArray *)sortedEntries {
	return [self sortedArrayUsingDescriptors:[NSArray modifiedDescriptors]];
}

- (NSArray *)arrayByRemovingEntry:(WLEntry*)entry {
	return [self arrayByRemovingUniqueObject:entry equality:[[entry class] equalityBlock]];
}

- (BOOL)containsEntry:(WLEntry*)entry {
	return [self containsObject:entry byBlock:[[entry class] equalityBlock]];
}

@end

@implementation NSMutableArray (WLEntrySorting)

- (void)sortEntries {
	[self sortUsingDescriptors:[NSArray modifiedDescriptors]];
}

@end
