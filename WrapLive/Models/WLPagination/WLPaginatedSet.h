//
//  WLPagination.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLPaginatedRequest.h"

@class WLPaginatedSet;

@protocol WLPaginationEntry <NSObject>

@property (readonly, nonatomic) NSDate *paginationDate;

@end

@protocol WLPaginatedSetDelegate <NSObject>

- (void)paginatedSetChanged:(WLPaginatedSet*)group;

@end

@interface WLPaginatedSet : NSObject

@property (strong, nonatomic) NSMutableOrderedSet* entries;

@property (nonatomic) BOOL completed;

@property (strong, nonatomic) WLPaginatedRequest* request;

@property (nonatomic, weak) id <WLPaginatedSetDelegate> delegate;

@property (nonatomic, strong) NSComparator sortComparator;

@property (nonatomic) BOOL sortDescending;

+ (instancetype)setWithEntries:(NSOrderedSet*)entries request:(WLPaginatedRequest*)request;

+ (instancetype)setWithRequest:(WLPaginatedRequest*)request;

- (void)configureRequest:(WLPaginatedRequest*)request;

- (NSDate*)newerPaginationDate;

- (NSDate*)olderPaginationDate;

- (void)resetEntries:(NSOrderedSet*)entries;

- (void)fresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (void)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (void)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (void)handleResponse:(NSOrderedSet*)entries;

- (BOOL)addEntries:(NSOrderedSet *)entries;

- (BOOL)addEntry:(id)entry;

- (void)removeEntry:(id)entry;

- (void)sort;

- (void)sort:(id)entry;

@end

@interface WLEntry (WLPaginatedSet) <WLPaginationEntry>

@property (readonly, nonatomic) NSDate *paginationDate;

@end

@interface WLCandy (WLPaginatedSet)

@end
