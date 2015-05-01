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

- (id)tryObjectAtIndex:(NSUInteger)index;

@end

@interface NSArray (WLDataSourceItems) <WLDataSourceItems> @end

@interface NSOrderedSet (WLDataSourceItems) <WLDataSourceItems> @end

@interface WLPaginatedSet (WLDataSourceItems) <WLDataSourceItems> @end
