//
//  WLDataSourceItems.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDataSourceItems.h"
#import "WLCollections.h"

@implementation NSArray (WLDataSourceItems) @end

@implementation NSOrderedSet (WLDataSourceItems) @end

@implementation WLPaginatedSet (WLDataSourceItems)

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