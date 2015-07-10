//
//  NSSet+WLCollection.m
//  wrapLive
//
//  Created by Sergey Maximenko on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "NSSet+WLCollection.h"

@implementation NSSet (WLCollection)

- (BOOL)nonempty {
    return self.count > 0;
}

- (instancetype)mutate:(void (^)(id mutableCopy))mutation {
    id mutableCopy = [self mutableCopy];
    if (mutation) mutation(mutableCopy);
    return [mutableCopy copy];
}

- (instancetype)add:(id)object {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy add:object];
    }];
}

- (instancetype)adds:(id <WLCollection>)objects {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy adds:objects];
    }];
}

- (instancetype)remove:(id)object {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy add:object];
    }];
}

- (instancetype)removes:(id <WLCollection>)objects {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy removes:objects];
    }];
}

- (instancetype)map:(MapBlock)block {
    NSMutableSet *set = [NSMutableSet set];
    for (id object in self) {
        id _object = block(object);
        if (_object != nil) [set addObject:_object];
    }
    return set;
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
    return [self mutate:^(id mutableCopy) {
        [mutableCopy removeSelectively:enumerator];
    }];
}

- (instancetype)where:(NSString *)predicateFormat, ... {
    BEGIN_PREDICATE_FORMAT
    id result = [self filteredSetUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    END_PREDICATE_FORMAT
    return result;
}

- (instancetype)removeWhere:(NSString *)predicateFormat, ... {
    BEGIN_PREDICATE_FORMAT
    NSSet *objects = [self filteredSetUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    END_PREDICATE_FORMAT
    return [self removes:objects];
}

- (instancetype)replace:(id)object with:(id)replaceObject {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy replace:object with:replaceObject];
    }];
}

- (NSArray*)array {
    return [self allObjects];
}

- (NSSet*)set {
    return self;
}

- (NSOrderedSet*)orderedSet {
    return [NSOrderedSet orderedSetWithSet:self];
}

@end

@implementation NSMutableSet (WLCollection)

- (instancetype)mutate:(void (^)(id  mutableCopy))mutation {
    if (mutation) mutation(self);
    return self;
}

- (instancetype)add:(id)object {
    [self addObject:object];
    return self;
}

- (instancetype)adds:(id <WLCollection>)objects {
    [self unionSet:[objects set]];
    return self;
}

- (instancetype)remove:(id)object {
    [self removeObject:object];
    return self;
}

- (instancetype)removes:(id <WLCollection>)objects {
    [self minusSet:[objects set]];
    return self;
}

- (instancetype)removeSelectively:(SelectBlock)enumerator {
    for (id object in [self allObjects]) {
        if (enumerator(object)) {
            [self removeObject:object];
        }
    }
    return self;
}

- (instancetype)where:(NSString *)predicateFormat, ... {
    BEGIN_PREDICATE_FORMAT
    id result = [[self filteredSetUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]] mutableCopy];
    END_PREDICATE_FORMAT
    return result;
}

- (instancetype)replace:(id)object with:(id)replaceObject {
    [self removeObject:object];
    [self addObject:replaceObject];
    return self;
}

@end
