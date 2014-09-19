//
//  NSOrderedSet+Additions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLBlocks.h"

@interface NSOrderedSet (Additions)

@property (readonly, nonatomic) BOOL nonempty;

+ (instancetype)orderedSetWithBlock:(void (^)(NSMutableOrderedSet* set))block;

+ (instancetype)orderedSetByUnionOrderedSet:(NSOrderedSet *)first withOrdredSet:(NSOrderedSet *)second;

- (instancetype)mutate:(void (^)(NSMutableOrderedSet* mutableCopy))mutation;

- (instancetype)orderedSetByAddingObject:(id)object;

- (instancetype)orderedSetByAddingObjects:(NSOrderedSet *)objects;

- (instancetype)orderedSetByRemovingObject:(id)object;

- (instancetype)orderedSetByRemovingObjects:(NSOrderedSet *)objects;

- (instancetype)orderedSetByReplacingObject:(id)object withObject:(id)replaceObject;

- (instancetype)orderedSetByReplacingFirstObject:(id)replaceObject;

- (id)tryObjectAtIndex:(NSInteger)index;

- (instancetype)orderedSetByInsertingObjects:(NSOrderedSet *)objects atIndex:(NSUInteger)index;

- (instancetype)orderedSetByInsertingFirstObjects:(NSOrderedSet *)objects;

- (instancetype)orderedSetByInsertingObject:(id)object atIndex:(NSUInteger)index;

- (instancetype)orderedSetByInsertingFirstObject:(id)object;

- (instancetype)map:(MapBlock)block;

- (id)selectObject:(SelectBlock)block;

- (instancetype)selectObjects:(SelectBlock)block;

- (void)all:(EnumBlock)block;

- (BOOL)containsObject:(id)target byBlock:(EqualityBlock)block;

- (BOOL)match:(SelectBlock)block;

- (BOOL)containsIndex:(NSUInteger)index;

- (NSOrderedSet*)orderedSetByRemovingObjectsWhileEnumerating:(SelectBlock)enumerator;

@end

@interface NSMutableOrderedSet (Additions)

- (BOOL)replaceObject:(id)object withObject:(id)replaceObject;

- (BOOL)replaceFirstObject:(id)replaceObject;

- (BOOL)exchangeObject:(id)object withObjectAtIndex:(NSUInteger)replaceIndex;

- (BOOL)exchangeObject:(id)object withObject:(id)exchangeObject;

- (BOOL)moveObjectAtFirstIndex:(id)object;

- (BOOL)moveObjectPassingTestAtFirstIndex:(SelectBlock)block;

- (void)insertObjects:(NSOrderedSet *)objects atIndex:(NSUInteger)index;

- (void)insertFirstObjects:(NSOrderedSet *)objects;

- (void)insertFirstObject:(id)object;

- (void)removeObjectsWhileEnumerating:(SelectBlock)enumerator;

@end
