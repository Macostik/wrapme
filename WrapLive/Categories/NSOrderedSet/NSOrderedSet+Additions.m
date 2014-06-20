//
//  NSOrderedSet+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSOrderedSet+Additions.h"
#import "WLSupportFunctions.h"

@implementation NSOrderedSet (Additions)

+ (instancetype)orderedSetWithBlock:(void (^)(NSMutableOrderedSet *set))block {
	return [[NSMutableOrderedSet orderedSetWithBlock:block] copy];
}

+ (instancetype)orderedSetByUnionOrderedSet:(NSOrderedSet *)first withOrdredSet:(NSOrderedSet *)second {
    return [[NSMutableOrderedSet orderedSetByUnionOrderedSet:first withOrdredSet:second] copy];
}

- (BOOL)nonempty {
	return [self count] > 0;
}

- (NSOrderedSet*)mutate:(void (^)(NSMutableOrderedSet* mutableCopy))mutation {
	NSMutableOrderedSet *mutableCopy = [self mutableCopy];
	mutation(mutableCopy);
	return [mutableCopy copy];
}

- (instancetype)orderedSetByAddingObject:(id)object {
    return [self mutate:^void (NSMutableOrderedSet *mutableCopy) {
		[mutableCopy addObject:object];
	}];
}

- (instancetype)orderedSetByAddingObjects:(NSOrderedSet *)objects {
    return [self mutate:^void (NSMutableOrderedSet *mutableCopy) {
		[mutableCopy unionOrderedSet:objects];
	}];
}

- (NSOrderedSet *)orderedSetByRemovingObject:(id)object {
	return [self mutate:^void (NSMutableOrderedSet *mutableCopy) {
		[mutableCopy removeObject:object];
	}];
}

- (NSOrderedSet *)orderedSetByRemovingObjects:(NSOrderedSet *)objects {
	return [self mutate:^void (NSMutableOrderedSet *mutableCopy) {
		for (id object in objects) {
			if ([mutableCopy indexOfObject:object] != NSNotFound) {
				[mutableCopy removeObject:object];
			}
		}
	}];;
}

- (NSOrderedSet *)orderedSetByReplacingObject:(id)object withObject:(id)replaceObject {
	return [self mutate:^(NSMutableOrderedSet *mutableCopy) {
		[mutableCopy replaceObject:object withObject:replaceObject];
	}];
}

- (instancetype)orderedSetByReplacingFirstObject:(id)replaceObject {
    return [self mutate:^(NSMutableOrderedSet *mutableCopy) {
		[mutableCopy replaceFirstObject:replaceObject];
	}];
}

- (id)tryObjectAtIndex:(NSInteger)index {
	return [self containsIndex:index] ? self[index] : nil;
}

- (NSOrderedSet*)orderedSetByInsertingObjects:(NSOrderedSet *)objects atIndex:(NSUInteger)index {
	return [self mutate:^(NSMutableOrderedSet *mutableCopy) {
		[mutableCopy insertObjects:objects atIndex:index];
	}];
}

- (NSOrderedSet*)orderedSetByInsertingFirstObjects:(NSOrderedSet *)objects {
	return [self orderedSetByInsertingObjects:objects atIndex:0];
}

- (NSOrderedSet*)orderedSetByInsertingObject:(id)object atIndex:(NSUInteger)index {
	return [self mutate:^(NSMutableOrderedSet *mutableCopy) {
		[mutableCopy insertObject:object atIndex:index];
	}];
}

- (NSOrderedSet*)orderedSetByInsertingFirstObject:(id)object {
	return [self orderedSetByInsertingObject:object atIndex:0];
}

- (NSOrderedSet *)map:(MapBlock)block {
	NSMutableOrderedSet *result = [NSMutableOrderedSet orderedSet];
	for (id element in self) {
		id newElement = block(element);
		if (newElement != nil) [result addObject:newElement];
	}
	return [result copy];
}

- (id)selectObject:(SelectBlock)block {
	for (id item in self) {
		if (block(item)) {
			return item;
		}
	}
	return nil;
}

- (NSOrderedSet *)selectObjects:(SelectBlock)block {
	return [self map:^id(id item) {
		return block(item) ? item : nil;
	}];
}

- (void)all:(EnumBlock)block {
	for (id item in self) {
		block(item);
	}
}

- (BOOL)containsIndex:(NSUInteger)index {
	NSUInteger count = [self count];
	return count > 0 && IsInBounds(0, count - 1, index);
}

- (NSOrderedSet*)orderedSetByRemovingObjectsWhileEnumerating:(SelectBlock)enumerator {
	return [self mutate:^(NSMutableOrderedSet *mutableCopy) {
		[mutableCopy removeObjectsWhileEnumerating:enumerator];
	}];
}

@end

@implementation NSMutableOrderedSet (Additions)

+ (instancetype)orderedSetWithBlock:(void (^)(NSMutableOrderedSet *set))block {
    NSMutableOrderedSet* set = [NSMutableOrderedSet orderedSet];
	block(set);
	return set;
}

+ (instancetype)orderedSetByUnionOrderedSet:(NSOrderedSet *)first withOrdredSet:(NSOrderedSet *)second {
    NSMutableOrderedSet* set = [NSMutableOrderedSet orderedSetWithOrderedSet:first];
    [set unionOrderedSet:second];
    return set;
}

- (instancetype)mutate:(void (^)(NSMutableOrderedSet *))mutation {
    mutation(self);
    return self;
}

- (BOOL)replaceObject:(id)object withObject:(id)replaceObject {
	if (object && replaceObject) {
		NSInteger index = [self indexOfObject:object];
		if (index != NSNotFound) {
			[self replaceObjectAtIndex:index withObject:replaceObject];
			return YES;
		}
	}
	return NO;
}

- (BOOL)replaceFirstObject:(id)replaceObject {
    return [self replaceObject:[self firstObject] withObject:replaceObject];
}

- (BOOL)exchangeObject:(id)object withObjectAtIndex:(NSUInteger)replaceIndex {
	if (object && replaceIndex < [self count]) {
		NSUInteger index = [self indexOfObject:object];
		if (index != NSNotFound) {
			[self exchangeObjectAtIndex:index withObjectAtIndex:replaceIndex];
			return YES;
		}
	}
	return NO;
}

- (BOOL)exchangeObject:(id)object withObject:(id)exchangeObject {
	return [self exchangeObject:object withObjectAtIndex:[self indexOfObject:exchangeObject]];
}

- (BOOL)moveObjectAtFirstIndex:(id)object {
	return [self exchangeObject:object withObjectAtIndex:0];
}

- (BOOL)moveObjectPassingTestAtFirstIndex:(SelectBlock)block {
	return [self moveObjectAtFirstIndex:[self selectObject:block]];
}

- (void)insertObjects:(NSOrderedSet *)objects atIndex:(NSUInteger)index {
	if (objects.nonempty) {
		[self insertObjects:[objects array] atIndexes:[NSIndexSet indexSetWithIndex:index]];
	}
}

- (void)insertFirstObjects:(NSOrderedSet *)objects {
	[self insertObjects:objects atIndex:0];
}

- (void)insertFirstObject:(id)object {
	[self insertObject:object atIndex:0];
}

- (void)removeObjectsWhileEnumerating:(SelectBlock)enumerator {
	NSUInteger index = 0;
	while ([self containsIndex:index]) {
		id item = self[index];
		if (enumerator(item)) {
			[self removeObject:item];
		} else {
			index++;
		}
	}
}

@end
