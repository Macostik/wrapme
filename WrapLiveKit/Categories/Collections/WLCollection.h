//
//  CollectionHelper.h
//  wrapLive
//
//  Created by Sergey Maximenko on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLDefinedComparators.h"

@protocol WLCollection <NSObject>

@property (readonly, nonatomic) BOOL nonempty;

- (instancetype)mutate:(void (^)(id mutableCopy))mutation;

- (instancetype)add:(id)object;

- (instancetype)adds:(id <WLCollection>)objects;

- (instancetype)remove:(id)object;

- (instancetype)removes:(id <WLCollection>)objects;

- (instancetype)map:(MapBlock)block;

- (id)select:(SelectBlock)block;

- (instancetype)selects:(SelectBlock)block;

- (void)all:(EnumBlock)block;

- (BOOL)match:(SelectBlock)block;

- (instancetype)removeSelectively:(SelectBlock)enumerator;

- (instancetype)where:(NSString *)predicateFormat, ...;

- (instancetype)removeWhere:(NSString *)predicateFormat, ...;

- (instancetype)replace:(id)object with:(id)replaceObject;

- (NSArray*)array;

- (NSSet*)set;

- (NSOrderedSet*)orderedSet;

@end

@protocol WLBaseOrderedCollection <NSObject>

@property (nonatomic, readonly) NSUInteger count;

- (id)objectAtIndex:(NSUInteger)index;

- (id)tryAt:(NSUInteger)index;

@end

@protocol WLOrderedCollection <WLCollection, WLBaseOrderedCollection>

- (BOOL)containsAt:(NSUInteger)index;

- (instancetype)insert:(id)object at:(NSUInteger)index;

- (instancetype)sort;

- (instancetype)sort:(NSComparator)comparator;

- (instancetype)sort:(NSComparator)comparator descending:(BOOL)descending;

- (instancetype)sortByUpdatedAt;

- (instancetype)sortByCreatedAt;

- (instancetype)sortByUpdatedAt:(BOOL)descending;

- (instancetype)sortByCreatedAt:(BOOL)descending;

- (instancetype)add:(id)object comparator:(NSComparator)comparator descending:(BOOL)descending;

@end

#define BEGIN_PREDICATE_FORMAT \
va_list args;\
va_start(args, predicateFormat);\

#define END_PREDICATE_FORMAT va_end(args);


