//
//  WLDataSourceItems.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet+WLBaseOrderedCollection.h"
#import "WLCollections.h"

@implementation WLPaginatedSet (WLBaseOrderedCollection)

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