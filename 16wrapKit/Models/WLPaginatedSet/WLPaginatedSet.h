//
//  WLPagination.h
//  moji
//
//  Created by Ravenpod on 7/14/14.
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

- (void)paginatedSetCompleted:(WLPaginatedSet *)group;

@end

@interface WLPaginatedSet : NSObject

@property (strong, nonatomic) NSMutableOrderedSet* entries;

@property (nonatomic) BOOL completed;

@property (strong, nonatomic) WLPaginatedRequest* request;

@property (nonatomic, weak) id <WLPaginatedSetDelegate> delegate;

@property (nonatomic, strong) NSComparator sortComparator;

@property (nonatomic) BOOL sortDescending;

+ (instancetype)setWithEntries:(NSSet*)entries request:(WLPaginatedRequest*)request;

+ (instancetype)setWithRequest:(WLPaginatedRequest*)request;

- (void)configureRequest:(WLPaginatedRequest*)request;

- (NSDate*)newerPaginationDate;

- (NSDate*)olderPaginationDate;

- (void)resetEntries:(NSSet*)entries;

- (void)fresh:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (void)newer:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (void)older:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (void)handleResponse:(NSSet*)entries;

- (BOOL)addEntries:(NSSet *)entries;

- (BOOL)addEntry:(id)entry;

- (void)removeEntry:(id)entry;

- (void)sort;

- (void)sort:(id)entry;

- (void)recursiveOlder:(WLFailureBlock)failure;

- (void)didChange;

- (void)didBecomeCompleted;

@end

@interface WLEntry (WLPaginatedSet) <WLPaginationEntry>

@property (readonly, nonatomic) NSDate *paginationDate;

@end

@interface WLCandy (WLPaginatedSet)

@end