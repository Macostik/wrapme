//
//  NSMutableOrderedSet+Sorting.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/23/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSComparator defaultComparator;

extern NSComparator comparatorByUpdatedAt;

extern NSComparator comparatorByCreatedAt;

extern NSComparator comparatorByCreatedAtTimestamp;

extern NSComparator comparatorByDate;

extern NSComparator comparatorByName;

@interface NSMutableOrderedSet (Sorting)

- (BOOL)sort;

- (BOOL)sort:(NSComparator)comparator;

- (BOOL)sort:(NSComparator)comparator descending:(BOOL)descending;

- (BOOL)sortByUpdatedAt;

- (BOOL)sortByCreatedAt;

- (BOOL)sortByUpdatedAt:(BOOL)descending;

- (BOOL)sortByCreatedAt:(BOOL)descending;

- (void)addObject:(id)object comparator:(NSComparator)comparator descending:(BOOL)descending;

@end
