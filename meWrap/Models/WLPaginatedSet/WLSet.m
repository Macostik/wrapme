//
//  WLSet.m
//  Moji
//
//  Created by Sergey Maximenko on 8/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSet.h"
#import "WLCollections.h"

@implementation WLSet

- (instancetype)init {
    self = [super init];
    if (self) {
        self.entries = [NSMutableOrderedSet orderedSet];
        self.sortComparator = comparatorByUpdatedAt;
        self.sortDescending = YES;
    }
    return self;
}

- (void)resetEntries:(NSSet *)entries {
    [self.entries removeAllObjects];
    [self.entries unionSet:entries];
    [self sort];
}

- (void)didChange {
    [self.delegate setDidChange:self];
}

- (BOOL)addEntries:(NSSet *)entries {
    if (!entries.nonempty || [entries isSubsetOfSet:self.entries.set]) {
        return NO;
    }
    [self.entries unionSet:entries];
    [self sort];
    return YES;
}

- (BOOL)addEntry:(id)entry {
    if ([self.entries containsObject:entry]) {
        return NO;
    }
    [self.entries add:entry comparator:self.sortComparator descending:self.sortDescending];
    [self didChange];
    return YES;
}

- (void)removeEntry:(id)entry {
    if ([self.entries containsObject:entry]) {
        [self.entries removeObject:entry];
        [self didChange];
    }
}

- (void)sort {
    [self.entries sort:self.sortComparator descending:self.sortDescending];
    [self didChange];
}

- (void)sort:(id)entry {
    if ([self.entries containsObject:entry]) {
        [self sort];
    } else {
        [self addEntry:entry];
    }
}

// MARK: - WLBaseOrderedCollection

- (NSUInteger)count {
    return self.entries.count;
}

- (id)objectAtIndex:(NSUInteger)index {
    return [self.entries objectAtIndex:index];
}

- (id)tryAt:(NSUInteger)index {
    return [self.entries tryAt:index];
}

@end
