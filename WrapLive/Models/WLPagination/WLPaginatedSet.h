//
//  WLPagination.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLBlocks.h"
#import "WLPaginatedRequest.h"

@class WLPaginatedSet;

@protocol WLPaginatedSetDelegate <NSObject>

- (void)paginatedSetChanged:(WLPaginatedSet*)group;

@end

@interface WLPaginatedSet : NSObject

@property (strong, nonatomic) NSMutableOrderedSet* entries;

@property (nonatomic) BOOL completed;

@property (strong, nonatomic) WLPaginatedRequest* request;

@property (nonatomic, weak) id <WLPaginatedSetDelegate> delegate;

@property (nonatomic, strong) NSComparator sortComparator;

+ (instancetype)setWithEntries:(NSOrderedSet*)entries request:(WLPaginatedRequest*)request;

+ (instancetype)setWithRequest:(WLPaginatedRequest*)request;

- (void)resetEntries:(NSOrderedSet*)entries;

- (id)fresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)send:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (void)handleResponse:(NSOrderedSet*)entries success:(WLOrderedSetBlock)success;

- (BOOL)addEntries:(NSOrderedSet *)entries;

- (BOOL)addEntry:(id)entry;

- (BOOL)addEntries:(NSOrderedSet *)entries sort:(BOOL)sort;

- (BOOL)addEntry:(id)entry sort:(BOOL)sort;

- (void)removeEntry:(id)entry;

- (void)sort;

- (void)sort:(id)entry;

- (BOOL)shouldAddEntry:(id)entry;

@end
