//
//  NSArray+Additions.m
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 8/1/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "NSArray+Additions.h"

@implementation NSArray (Additions)

+ (instancetype)arrayWithBlock:(void (^)(NSMutableArray *array))block {
	return [[NSMutableArray arrayWithBlock:block] copy];
}

- (BOOL)nonempty {
	return [self count] > 0;
}

- (NSArray*)mutate:(void (^)(NSMutableArray* mutableCopy))mutation {
	NSMutableArray *mutableCopy = [self mutableCopy];
	mutation(mutableCopy);
	return [mutableCopy copy];
}

- (NSArray *)arrayByRemovingObject:(id)object {
	return [self mutate:^void (NSMutableArray *mutableCopy) {
		[mutableCopy removeObject:object];
	}];
}

- (NSArray *)arrayByRemovingObjectsFromArray:(NSArray *)array {
	return [self mutate:^void (NSMutableArray *mutableCopy) {
		for (id object in array) {
			if ([mutableCopy indexOfObject:object] != NSNotFound) {
				[mutableCopy removeObject:object];
			}
		}
	}];;
}

- (NSArray *)arrayByReplacingObject:(id)object withObject:(id)replaceObject {
	return [self mutate:^(NSMutableArray *mutableCopy) {
		[mutableCopy replaceObject:object withObject:replaceObject];
	}];
}

- (id)tryObjectAtIndex:(NSInteger)index {
	return [self containsIndex:index] ? self[index] : nil;
}

- (NSArray *)arrayByAddingUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality {
	return [self mutate:^(NSMutableArray *mutableCopy) {
		[mutableCopy addUniqueObjects:objects equality:equality];
	}];
}

- (NSArray*)arrayByInsertingUniqueObjects:(NSArray *)objects atIndex:(NSUInteger)index equality:(EqualityBlock)equality {
	return [self mutate:^(NSMutableArray *mutableCopy) {
		[mutableCopy insertUniqueObjects:objects atIndex:index equality:equality];
	}];
}

- (NSArray*)arrayByInsertingFirstUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality {
	return [self arrayByInsertingUniqueObjects:objects atIndex:0 equality:equality];
}

- (NSArray *)arrayByAddingUniqueObject:(id)object equality:(EqualityBlock)equality {
	return [self mutate:^(NSMutableArray *mutableCopy) {
		[mutableCopy addUniqueObject:object equality:equality];
	}];
}

- (NSArray*)arrayByInsertingUniqueObject:(id)object atIndex:(NSUInteger)index equality:(EqualityBlock)equality {
	return [self mutate:^(NSMutableArray *mutableCopy) {
		[mutableCopy insertUniqueObject:object atIndex:index equality:equality];
	}];
}

- (NSArray*)arrayByInsertingFirstUniqueObject:(id)object equality:(EqualityBlock)equality {
	return [self arrayByInsertingUniqueObject:object atIndex:0 equality:equality];
}

- (NSArray *)arrayByRemovingUniqueObject:(id)object equality:(EqualityBlock)equality {
	return [self mutate:^(NSMutableArray *mutableCopy) {
		[mutableCopy removeUniqueObject:object equality:equality];
	}];
}

- (NSArray *)arrayByRemovingUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality {
	return [self mutate:^(NSMutableArray *mutableCopy) {
		[mutableCopy removeUniqueObjects:objects equality:equality];
	}];
}

- (instancetype)map:(MapBlock)block {
	NSMutableArray *result = [NSMutableArray array];
	for (id element in self) {
		id newElement = block(element);
		if (newElement != nil) [result addObject:newElement];
	}
    return [[self class] arrayWithArray:result];
}

- (id)selectObject:(SelectBlock)block {
	for (id item in self) {
		if (block(item)) {
			return item;
		}
	}
	return nil;
}

- (instancetype)selectObjects:(SelectBlock)block {
	return [self map:^id(id item) {
		return block(item) ? item : nil;
	}];
}

- (NSUInteger)indexOfObjectEqualToObject:(id)object equality:(EqualityBlock)equality {
	return [self indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		return equality(obj, object);
	}];
}

- (id)selectObjectEqualToObject:(id)object equality:(EqualityBlock)equality {
	return [self selectObject:^BOOL(id item) {
		return equality(item, object);
	}];
}

- (NSIndexSet*)indexesOfObjectsEqualToObject:(id)object equality:(EqualityBlock)equality {
	return [self indexesOfObjectsPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
	    return equality(obj, object);
	}];
}

- (NSArray*)selectObjectsEqualToObject:(id)object equality:(EqualityBlock)equality {
	return [self selectObjects:^BOOL(id item) {
		return equality(item, object);
	}];
}

- (NSIndexSet*)indexesOfObjectsEqualToObjects:(NSArray*)objects equality:(EqualityBlock)equality {
	return [self indexesOfObjectsPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
	    NSInteger index = [objects indexOfObjectPassingTest: ^BOOL (id object, NSUInteger idx, BOOL *stop) {
	        return equality(obj, object);
		}];
	    return index != NSNotFound;
	}];
}

- (NSArray*)selectObjectsEqualToObjects:(NSArray*)objects equality:(EqualityBlock)equality {
	return [self selectObjects:^BOOL(id item) {
		return [objects containsObject:item byBlock:equality];
	}];
}

- (void)all:(EnumBlock)block {
	for (id item in self) {
		block(item);
	}
}

- (BOOL)containsObject:(id)target byBlock:(EqualityBlock)block {
	for (id item in self) {
		if (block(target, item)) {
			return YES;
		}
	}
	return NO;
}

- (NSArray *)uniqueByBlock:(EqualityBlock)block {
	NSMutableArray *result = [NSMutableArray array];
	for (id item in self) {
		if (![result containsObject:item byBlock:block]) {
			[result addObject:item];
		}
	}
	return result;
}

- (NSArray *)unique {
	return [self uniqueByBlock: ^BOOL (id first, id second) {
		return [first isEqual:second];
	}];
}

- (BOOL)containsIndex:(NSUInteger)index {
	NSUInteger count = [self count];
	return count > 0 && IsInBounds(0, count - 1, index);
}

- (NSArray*)arrayByRemovingObjectsWhileEnumerating:(SelectBlock)enumerator {
	return [self mutate:^(NSMutableArray *mutableCopy) {
		[mutableCopy removeObjectsWhileEnumerating:enumerator];
	}];
}

- (instancetype)objectsWhere:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    va_end(args);
    if (predicateFormat && ![predicateFormat isKindOfClass:[NSString class]]) {
        NSString *reason = @"predicate must be an NSString with optional format va_list";
        [NSException exceptionWithName:@"WLException" reason:reason userInfo:nil];
    }
    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

@end

@implementation NSMutableArray (Additions)

+ (instancetype)arrayWithBlock:(void (^)(NSMutableArray *array))block {
    NSMutableArray* array = [NSMutableArray array];
	block(array);
	return array;
}

- (BOOL)tryAddObject:(id)object {
    if (object) {
        [self addObject:object];
        return YES;
    }
    return NO;
}

- (void)tryAddObjects:(id)object, ... {
	va_list args;
    va_start(args, object);
    for (; object != nil; object = va_arg(args, id)) {
		[self tryAddObject:object];
	}
    va_end(args);
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

- (void)addUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality {
	objects = [objects uniqueByBlock:equality];
	if ([objects count] == 0) {
		return;
	}
	NSIndexSet *indexes = [self indexesOfObjectsEqualToObjects:objects equality:equality];
	if ([indexes count] > 0) {
		[self removeObjectsAtIndexes:indexes];
	}
	[self addObjectsFromArray:objects];
}

- (void)insertUniqueObjects:(NSArray *)objects atIndex:(NSUInteger)index equality:(EqualityBlock)equality {
	if (objects.nonempty) {
		[self removeUniqueObjects:objects equality:equality];
		[self insertObjects:objects atIndexes:[NSIndexSet indexSetWithIndex:0]];
	}
}

- (void)insertFirstUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality {
	[self insertUniqueObjects:objects atIndex:0 equality:equality];
}

- (void)addUniqueObject:(id)object equality:(EqualityBlock)equality {
	if (!object) {
		return;
	}
	NSIndexSet *indexes = [self indexesOfObjectsEqualToObject:object equality:equality];
	if ([indexes count] > 0) {
		[self removeObjectsAtIndexes:indexes];
		NSUInteger index = [indexes firstIndex];
		if(index <= [self count]) {
			[self insertObject:object atIndex:index];
		} else {
			[self addObject:object];
		}
	} else {
		[self addObject:object];
	}
}

- (void)insertUniqueObject:(id)object atIndex:(NSUInteger)index equality:(EqualityBlock)equality {
	if (object) {
		[self removeUniqueObject:object equality:equality];
		[self insertObject:object atIndex:index];
	}
}

- (void)insertFirstUniqueObject:(id)object equality:(EqualityBlock)equality {
	[self insertUniqueObject:object atIndex:0 equality:equality];
}

- (BOOL)removeUniqueObject:(id)object equality:(EqualityBlock)equality {
	if (object) {
		NSIndexSet *indexes = [self indexesOfObjectsEqualToObject:object equality:equality];
		if ([indexes count] > 0) {
			[self removeObjectsAtIndexes:indexes];
			return YES;
		}
	}
	return NO;
}

- (BOOL)removeUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality {
	if (objects.nonempty) {
		NSIndexSet *indexes = [self indexesOfObjectsEqualToObjects:objects equality:equality];
		if ([indexes count] > 0) {
			[self removeObjectsAtIndexes:indexes];
			return YES;
		}
	}
	return NO;
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
