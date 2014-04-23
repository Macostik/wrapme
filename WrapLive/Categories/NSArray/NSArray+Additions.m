//
//  NSArray+Additions.m
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 8/1/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "NSArray+Additions.h"

@implementation NSArray (Additions)

- (NSArray *)arrayByRemovingObject:(id)object {
	NSMutableArray *newArray = [NSMutableArray arrayWithArray:self];
	[newArray removeObject:object];
	return [NSArray arrayWithArray:newArray];
}

- (NSArray *)arrayByRemovingObjectsFromArray:(NSArray *)array {
	NSMutableArray *newArray = [NSMutableArray arrayWithArray:self];
	
	for (id object in array) {
		if ([newArray indexOfObject:object] != NSNotFound) {
			[newArray removeObject:object];
		}
	}
	
	return [NSArray arrayWithArray:newArray];
}

- (NSArray *)arrayByReplacingObject:(id)object withObject:(id)replaceObject {
	NSMutableArray *array = [NSMutableArray arrayWithArray:self];
	[array replaceObject:object withObject:replaceObject];
	return [NSArray arrayWithArray:array];
}

- (id)safeObjectAtIndex:(NSInteger)index {
	return (index >= 0 && index < self.count) ? self[index] : nil;
}

- (NSArray *)enumerateObj:(id (^)(id obj))enumerateObj {
	NSMutableArray *array = [NSMutableArray array];
	
	for (id object in self) {
		id resultObject = enumerateObj(object);
		if (resultObject) {
			[array addObject:resultObject];
		}
	}
	return array;
}

+ (instancetype)arrayWithResourcePropertyListNamed:(NSString *)name {
	return [self arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"plist"]];
}

- (NSArray *)arrayByAddingUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality {
	NSIndexSet *indexes = [self indexesOfObjectsPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
	    NSInteger index = [objects indexOfObjectPassingTest: ^BOOL (id object, NSUInteger idx, BOOL *stop) {
	        return equality(obj, object);
		}];
	    return index != NSNotFound;
	}];
	
	NSMutableArray *_objects = [self mutableCopy];
	
	if ([indexes count] > 0) {
		[_objects removeObjectsAtIndexes:indexes];
	}
	
	[_objects addObjectsFromArray:objects];
	return [NSArray arrayWithArray:_objects];
}

- (NSArray *)arrayByAddingUniqueObject:(id)object equality:(EqualityBlock)equality {
	NSIndexSet *indexes = [self indexesOfObjectsPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
	    return equality(obj, object);
	}];
	
	NSMutableArray *_objects = [self mutableCopy];
	
	if ([indexes count] > 0) {
		[_objects removeObjectsAtIndexes:indexes];
	}
	
	[_objects addObject:object];
	return [NSArray arrayWithArray:_objects];
}

- (NSArray *)arrayByRemovingUniqueObject:(id)object equality:(EqualityBlock)equality {
	NSIndexSet *indexes = [self indexesOfObjectsPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
	    return equality(obj, object);
	}];
	if ([indexes count] > 0) {
		NSMutableArray *_objects = [self mutableCopy];
		[_objects removeObjectsAtIndexes:indexes];
		return [NSArray arrayWithArray:_objects];
	} else {
		return self;
	}
}

- (NSArray *)arrayByRemovingUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality {
	NSIndexSet *indexes = [self indexesOfObjectsPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
	    NSInteger index = [objects indexOfObjectPassingTest: ^BOOL (id object, NSUInteger idx, BOOL *stop) {
	        return equality(obj, object);
		}];
	    return index != NSNotFound;
	}];
	if ([indexes count] > 0) {
		NSMutableArray *_objects = [self mutableCopy];
		[_objects removeObjectsAtIndexes:indexes];
		return [NSArray arrayWithArray:_objects];
	} else {
		return self;
	}
}

- (NSArray *)map:(MapBlock)block {
	NSMutableArray *result = [NSMutableArray array];
	for (id element in self) {
		id newElement = block(element);
		if (newElement != nil) [result addObject:newElement];
	}
	return [NSArray arrayWithArray:result];
}

- (id)selectObject:(SelectBlock)block {
	for (id item in self) {
		if (block(item)) {
			return item;
		}
	}
	return nil;
}

- (NSArray *)selectObjects:(SelectBlock)block {
	return [self map:^id(id item) {
		return block(item) ? item : nil;
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

@end

@implementation NSMutableArray (Additions)

- (BOOL)replaceObject:(id)object withObject:(id)replaceObject {
	NSInteger index = [self indexOfObject:object];
	if (index != NSNotFound) {
		[self replaceObjectAtIndex:index withObject:replaceObject];
		return YES;
	}
	return NO;
}

- (void)addUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality {
	if (!objects) {
		return;
	}
	
	objects = [objects uniqueByBlock:equality];
	
	NSIndexSet *indexes = [self indexesOfObjectsPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
	    NSInteger index = [objects indexOfObjectPassingTest: ^BOOL (id object, NSUInteger idx, BOOL *stop) {
	        return equality(obj, object);
		}];
	    return index != NSNotFound;
	}];
		
	if ([indexes count] > 0) {
		[self removeObjectsAtIndexes:indexes];
	}
	[self addObjectsFromArray:objects];
}

- (void)addUniqueObject:(id)object equality:(EqualityBlock)equality {
	if (!object) {
		return;
	}
	NSIndexSet *indexes = [self indexesOfObjectsPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
	    return equality(obj, object);
	}];
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

- (BOOL)removeUniqueObject:(id)object equality:(EqualityBlock)equality {
	if (!object) {
		return NO;
	}
	NSIndexSet *indexes = [self indexesOfObjectsPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
	    return equality(obj, object);
	}];
	if ([indexes count] > 0) {
		[self removeObjectsAtIndexes:indexes];
		return YES;
	}
	else {
		return NO;
	}
}

@end
