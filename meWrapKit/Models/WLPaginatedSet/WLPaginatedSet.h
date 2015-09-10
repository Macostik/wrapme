//
//  WLPagination.h
//  meWrap
//
//  Created by Ravenpod on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSet.h"
#import "WLPaginatedRequest.h"

@class WLPaginatedSet;

@protocol WLPaginationEntry <NSObject>

@property (readonly, nonatomic) NSDate *paginationDate;

@end

@protocol WLPaginatedSetDelegate <WLSetDelegate>

- (void)paginatedSetDidComplete:(WLPaginatedSet *)set;

@end

@interface WLPaginatedSet : WLSet

@property (nonatomic) BOOL completed;

@property (strong, nonatomic) WLPaginatedRequest* request;

@property (nonatomic, weak) id <WLPaginatedSetDelegate> delegate;

+ (instancetype)setWithEntries:(NSSet*)entries request:(WLPaginatedRequest*)request;

+ (instancetype)setWithRequest:(WLPaginatedRequest*)request;

- (void)configureRequest:(WLPaginatedRequest*)request;

- (NSDate*)newerPaginationDate;

- (NSDate*)olderPaginationDate;

- (void)fresh:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (void)newer:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (void)older:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (void)handleResponse:(NSSet*)entries;

- (void)recursiveOlder:(WLFailureBlock)failure;

- (void)didComplete;

@end

@interface WLEntry (WLPaginatedSet) <WLPaginationEntry>

@property (readonly, nonatomic) NSDate *paginationDate;

@end

@interface WLCandy (WLPaginatedSet)

@end
