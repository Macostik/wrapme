//
//  NSArray+Additions.h
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 8/1/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Additions)

@property (readonly, nonatomic) BOOL nonempty;

+ (instancetype)arrayWithBlock:(void (^)(NSMutableArray* array))block;

- (NSArray*)mutate:(void (^)(NSMutableArray* mutableCopy))mutation;

- (NSArray*)arrayByRemovingObject:(id)object;

- (NSArray*)arrayByRemovingObjectsFromArray:(NSArray *)array;

- (NSArray*)arrayByReplacingObject:(id)object withObject:(id)replaceObject;

- (id)safeObjectAtIndex:(NSInteger)index;

- (NSArray*)arrayByAddingUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality;

- (NSArray*)arrayByInsertingUniqueObjects:(NSArray *)objects atIndex:(NSUInteger)index equality:(EqualityBlock)equality;

- (NSArray*)arrayByInsertingFirstUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality;

- (NSArray*)arrayByAddingUniqueObject:(id)object equality:(EqualityBlock)equality;

- (NSArray*)arrayByInsertingUniqueObject:(id)object atIndex:(NSUInteger)index equality:(EqualityBlock)equality;

- (NSArray*)arrayByInsertingFirstUniqueObject:(id)object equality:(EqualityBlock)equality;

- (NSArray*)arrayByRemovingUniqueObject:(id)object equality:(EqualityBlock)equality;

- (NSArray*)arrayByRemovingUniqueObjects:(NSArray*)objects equality:(EqualityBlock)equality;

- (NSArray*)map:(MapBlock)block;

- (id)selectObject:(SelectBlock)block;

- (NSArray*)selectObjects:(SelectBlock)block;

- (NSUInteger)indexOfObjectEqualToObject:(id)object equality:(EqualityBlock)equality;

- (id)selectObjectEqualToObject:(id)object equality:(EqualityBlock)equality;

- (NSIndexSet*)indexesOfObjectsEqualToObject:(id)object equality:(EqualityBlock)equality;

- (NSArray*)selectObjectsEqualToObject:(id)object equality:(EqualityBlock)equality;

- (NSIndexSet*)indexesOfObjectsEqualToObjects:(NSArray*)objects equality:(EqualityBlock)equality;

- (NSArray*)selectObjectsEqualToObjects:(NSArray*)objects equality:(EqualityBlock)equality;

- (void)all:(EnumBlock)block;

- (NSArray*)unique;

- (NSArray*)uniqueByBlock:(EqualityBlock)block;

- (BOOL)containsObject:(id)target byBlock:(EqualityBlock)block;

- (BOOL)containsIndex:(NSUInteger)index;

- (NSArray*)arrayByRemovingObjectsWhileEnumerating:(SelectBlock)enumerator;

- (instancetype)objectsWhere:(NSString *)predicateFormat, ...;

@end

@interface NSMutableArray (Additions)

- (BOOL)tryAddObject:(id)object;

- (void)tryAddObjects:(id)object, ... NS_REQUIRES_NIL_TERMINATION;

- (BOOL)replaceObject:(id)object withObject:(id)replaceObject;

- (BOOL)exchangeObject:(id)object withObjectAtIndex:(NSUInteger)replaceIndex;

- (BOOL)exchangeObject:(id)object withObject:(id)exchangeObject;

- (BOOL)moveObjectAtFirstIndex:(id)object;

- (BOOL)moveObjectPassingTestAtFirstIndex:(SelectBlock)block;

- (void)addUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality;

- (void)insertUniqueObjects:(NSArray *)objects atIndex:(NSUInteger)index equality:(EqualityBlock)equality;

- (void)insertFirstUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality;

- (void)addUniqueObject:(id)object equality:(EqualityBlock)equality;

- (void)insertUniqueObject:(id)object atIndex:(NSUInteger)index equality:(EqualityBlock)equality;

- (void)insertFirstUniqueObject:(id)object equality:(EqualityBlock)equality;

- (BOOL)removeUniqueObject:(id)object equality:(EqualityBlock)equality;

- (BOOL)removeUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality;

- (void)removeObjectsWhileEnumerating:(SelectBlock)enumerator;

@end
