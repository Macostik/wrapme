//
//  NSMutableOrderedSet+Sorting.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/23/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSComparator comparatorByUpdatedAtAscending;

extern NSComparator comparatorByUpdatedAtDescending;

extern NSComparator comparatorByCreatedAtAscending;

extern NSComparator comparatorByCreatedAtDescending;

extern NSComparator comparatorByDateAscending;

extern NSComparator comparatorByDateDescending;

@interface NSMutableOrderedSet (Sorting)

- (void)sort:(NSComparator)comparator;

- (void)sortByUpdatedAtDescending;

- (void)sortByUpdatedAtAscending;

- (void)sortByCreatedAtDescending;

- (void)sortByCreatedAtAscending;;

@end
