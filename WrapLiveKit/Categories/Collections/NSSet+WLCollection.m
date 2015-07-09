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

- (instancetype)adds:(id)objects {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy adds:objects];
    }];
}

- (instancetype)remove:(id)object {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy add:object];
    }];
}

- (instancetype)removes:(id)objects {
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
    return [set copy];
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
    PREDICATE_FORMAT
    return [self filteredSetUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (instancetype)removeWhere:(NSString *)predicateFormat, ... {
    PREDICATE_FORMAT
    NSSet *objects = [self filteredSetUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    return [self removes:objects];
}

- (instancetype)replace:(id)object with:(id)replaceObject {
    return [self mutate:^(id mutableCopy) {
        [mutableCopy replace:object with:replaceObject];
    }];
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

- (instancetype)adds:(id)objects {
    [self unionSet:objects];
    return self;
}

- (instancetype)remove:(id)object {
    [self removeObject:object];
    return self;
}

- (instancetype)removes:(id)objects {
    [self minusSet:objects];
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
    PREDICATE_FORMAT
    return [[self filteredSetUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]] mutableCopy];
}

- (instancetype)replace:(id)object with:(id)replaceObject {
    [self removeObject:object];
    [self addObject:replaceObject];
    return self;
}

@end
