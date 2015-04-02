//
//  NSMutableOrderedSet+Sorting.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/23/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSMutableOrderedSet+Sorting.h"
#import "NSOrderedSet+Additions.h"
#import "NSDate+Additions.h"
#import "WLEntryManager.h"

NSComparator defaultComparator = ^NSComparisonResult(id obj1, id obj2) {
    return [obj1 compare:obj2];
};

NSComparator comparatorByUpdatedAt = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj1 updatedAt] compare:[obj2 updatedAt]];
};

NSComparator comparatorByCreatedAt = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj1 createdAt] compare:[obj2 createdAt]];
};

NSComparator comparatorByDate = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj1 date] compare:[obj2 date]];
};

NSComparator comparatorByName = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj2 name] compare:[obj1 name] options:NSCaseInsensitiveSearch];
};

@implementation NSMutableOrderedSet (Sorting)

- (BOOL)sort {
    return [self sort:defaultComparator];
}

- (BOOL)sort:(NSComparator)comparator {
    return [self sort:comparator descending:YES];
}

- (BOOL)sort:(NSComparator)comparator descending:(BOOL)descending {
    __block BOOL changed = NO;
    [self sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSComparisonResult result = descending ? comparator(obj2, obj1) : comparator(obj1, obj2);
        if (!changed && result != NSOrderedAscending) {
            changed = YES;
        }
        return result;
    }];
    return changed;
}

- (BOOL)sortByUpdatedAt {
    return [self sortByUpdatedAt:YES];
}

- (BOOL)sortByCreatedAt {
    return [self sortByCreatedAt:YES];
}

- (BOOL)sortByUpdatedAt:(BOOL)descending {
    return [self sort:comparatorByUpdatedAt descending:descending];
}

- (BOOL)sortByCreatedAt:(BOOL)descending {
    return [self sort:comparatorByCreatedAt descending:descending];
}

- (void)addObject:(id)object comparator:(NSComparator)comparator descending:(BOOL)descending {
    NSUInteger index = [self indexOfObject:object inSortedRange:NSMakeRange(0, self.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
        return descending ? comparator(obj2, obj1) : comparator(obj1, obj2);
    }];
    if (index != NSNotFound) {
        [self insertObject:object atIndex:index];
    } else {
        [self addObject:object];
    }
}

@end
