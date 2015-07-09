//
//  NSArray+WLCollection.m
//  wrapLive
//
//  Created by Sergey Maximenko on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "NSArray+WLCollection.h"

@implementation NSArray (WLCollection)

- (BOOL)nonempty {
    return self.count > 0;
}

- (instancetype)mutate:(void (^)(id <WLCollection> mutableCopy))mutation {
    id mutableCopy = [self mutableCopy];
    if (mutation) mutation(mutableCopy);
    return [mutableCopy copy];
}

- (instancetype)add:(id)object {
    return [self mutate:^(id<WLCollection> mutableCopy) {
        [mutableCopy add:object];
    }];
}

- (instancetype)adds:(id)objects {
    return [self mutate:^(id<WLCollection> mutableCopy) {
        [mutableCopy adds:objects];
    }];
}

- (instancetype)remove:(id)object {
    return [self mutate:^(id<WLCollection> mutableCopy) {
        [mutableCopy add:object];
    }];
}

- (instancetype)removes:(id)objects {
    return [self mutate:^(id<WLCollection> mutableCopy) {
        [mutableCopy removes:objects];
    }];
}

- (instancetype)map:(MapBlock)block {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    for (id object in self) {
        id _object = block(object);
        if (_object != nil) [array addObject:_object];
    }
    return [array copy];
}

- (id)select:(SelectBlock)block {
    for (id object in self) {
        if (block(object)) {
            return object;
        }
    }
    return nil;
}

- (instancetype)selects:(SelectBlock)block {
    return [self map:^id(id object) {
        return block(object) ? object : nil;
    }];
}

- (void)all:(EnumBlock)block {
    for (id object in self) {
        block(object);
    }
}

- (BOOL)match:(SelectBlock)block {
    for (id object in self) {
        if (block(object)) return YES;
    }
    return NO;
}

- (instancetype)removeSelectively:(SelectBlock)enumerator {
    return [self mutate:^(id<WLCollection> mutableCopy) {
        [mutableCopy removeSelectively:enumerator];
    }];
}

- (instancetype)where:(NSString *)predicateFormat, ... {
    PREDICATE_FORMAT
    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (instancetype)removeWhere:(NSString *)predicateFormat, ... {
    PREDICATE_FORMAT
    NSArray *objects = [self filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    return [self removes:objects];
}

- (instancetype)replace:(id)object with:(id)replaceObject {
    return [self mutate:^(id<WLCollection> mutableCopy) {
        [mutableCopy replace:object with:replaceObject];
    }];
}

- (id)tryAt:(NSInteger)index {
    return [self containsAt:index] ? self[index] : nil;
}

- (BOOL)containsAt:(NSUInteger)index {
    NSUInteger count = [self count];
    return count > 0 && IsInBounds(0, count - 1, index);
}

- (instancetype)insert:(id)object at:(NSUInteger)index {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy insert:object at:index];
    }];
}

- (instancetype)sort {
    return [self sort:defaultComparator descending:YES];
}

- (instancetype)sort:(NSComparator)comparator {
    return [self sort:comparator descending:YES];
}

- (instancetype)sort:(NSComparator)comparator descending:(BOOL)descending {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy sort:comparator descending:descending];
    }];
}

- (instancetype)sortByUpdatedAt {
    return [self sortByUpdatedAt:YES];
}

- (instancetype)sortByCreatedAt {
    return [self sortByCreatedAt:YES];
}

- (instancetype)sortByUpdatedAt:(BOOL)descending {
    return [self sort:comparatorByUpdatedAt descending:descending];
}

- (instancetype)sortByCreatedAt:(BOOL)descending {
    return [self sort:comparatorByCreatedAt descending:descending];
}

- (instancetype)add:(id)object comparator:(NSComparator)comparator descending:(BOOL)descending {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy add:object comparator:comparator descending:descending];
    }];
}

@end

@implementation NSMutableArray (WLCollection)

- (instancetype)mutate:(void (^)(id <WLCollection> mutableCopy))mutation {
    if (mutation) mutation(self);
    return self;
}

- (instancetype)add:(id)object {
    [self addObject:object];
    return self;
}

- (instancetype)adds:(id)objects {
    [self addObjectsFromArray:objects];
    return self;
}

- (instancetype)remove:(id)object {
    [self removeObject:object];
    return self;
}

- (instancetype)removes:(id)objects {
    [self removeObjectsInArray:objects];
    return self;
}

- (instancetype)removeSelectively:(SelectBlock)enumerator {
    for (id object in [self copy]) {
        if (enumerator(object)) {
            [self removeObject:object];
        }
    }
    return self;
}

- (instancetype)where:(NSString *)predicateFormat, ... {
    PREDICATE_FORMAT
    return [[self filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]] mutableCopy];
}

- (instancetype)replace:(id)object with:(id)replaceObject {
    if (object && replaceObject) {
        NSInteger index = [self indexOfObject:object];
        if (index != NSNotFound) {
            [self replaceObjectAtIndex:index withObject:replaceObject];
        }
    }
    return self;
}

- (instancetype)insert:(id)object at:(NSUInteger)index {
    [self insertObject:object atIndex:index];
    return self;
}

- (instancetype)sort:(NSComparator)comparator descending:(BOOL)descending {
    [self sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        return descending ? comparator(obj2, obj1) : comparator(obj1, obj2);
    }];
    return self;
}

- (instancetype)add:(id)object comparator:(NSComparator)comparator descending:(BOOL)descending {
    NSUInteger index = [self indexOfObject:object inSortedRange:NSMakeRange(0, self.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
        return descending ? comparator(obj2, obj1) : comparator(obj1, obj2);
    }];
    if (index != NSNotFound) {
        [self insertObject:object atIndex:index];
    } else {
        [self addObject:object];
    }
    return self;
}

@end
