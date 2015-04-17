//
//  WLDataSourceItems.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDataSourceItems.h"

@implementation NSArray (WLDataSourceItems) @end

@implementation NSOrderedSet (WLDataSourceItems) @end

@implementation WLPaginatedSet (WLDataSourceItems)

- (NSUInteger)count {
    return self.entries.count;
}

- (id)objectAtIndex:(NSUInteger)index {
    return [self.entries objectAtIndex:index];
}

- (id)tryObjectAtIndex:(NSUInteger)index {
    return [self.entries tryObjectAtIndex:index];
}

@end