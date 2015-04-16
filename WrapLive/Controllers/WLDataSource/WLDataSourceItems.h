//
//  WLDataSourceCollection.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLPaginatedSet.h"

@protocol WLDataSourceItems <NSObject>

@property (nonatomic, readonly) NSUInteger count;

- (id)objectAtIndex:(NSUInteger)index;

@end

@interface NSArray (WLDataSourceItems) <WLDataSourceItems> @end

@implementation NSArray (WLDataSourceItems) @end

@interface NSOrderedSet (WLDataSourceItems) <WLDataSourceItems> @end

@implementation NSOrderedSet (WLDataSourceItems) @end

@interface WLPaginatedSet (WLDataSourceItems) <WLDataSourceItems> @end

@implementation WLPaginatedSet (WLDataSourceItems)

- (NSUInteger)count {
    return self.entries.count;
}

- (id)objectAtIndex:(NSUInteger)index {
    return [self.entries objectAtIndex:index];
}

@end
