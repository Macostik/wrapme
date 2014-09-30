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

NSComparator comparatorByUpdatedAtAscending = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj1 updatedAt] compare:[obj2 updatedAt]];
};

NSComparator comparatorByUpdatedAtDescending = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj2 updatedAt] compare:[obj1 updatedAt]];
};

NSComparator comparatorByCreatedAtAscending = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj1 createdAt] compare:[obj2 createdAt]];
};

NSComparator comparatorByCreatedAtDescending = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj2 createdAt] compare:[obj1 createdAt]];
};

NSComparator comparatorByDateAscending = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj1 date] compare:[obj2 date]];
};

NSComparator comparatorByDateDescending = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj2 date] compare:[obj1 date]];
};

NSComparator comparatorByUserNameAscending = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj2 name] compare:[obj1 name] options:NSCaseInsensitiveSearch];
};

@implementation NSMutableOrderedSet (Sorting)

- (void)sort:(NSComparator)comparator {
    [self sortWithOptions:NSSortStable usingComparator:comparator];
}

- (void)sortByUpdatedAtDescending {
    [self sort:comparatorByUpdatedAtDescending];
}

- (void)sortByUpdatedAtAscending {
	[self sort:comparatorByUpdatedAtAscending];
}

- (void)sortByCreatedAtDescending {
    [self sort:comparatorByCreatedAtDescending];
}

- (void)sortByCreatedAtAscending {
    [self sort:comparatorByCreatedAtAscending];
}

- (void)addObject:(id)object comparator:(NSComparator)comparator {
    NSUInteger index = [self indexOfObject:object inSortedRange:NSMakeRange(0, self.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
    if (index != NSNotFound) {
        [self insertObject:object atIndex:index];
    } else {
        [self addObject:object];
    }
}

@end
