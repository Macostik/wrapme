//
//  WLPagination.h
//  meWrap
//
//  Created by Ravenpod on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSet.h"

@class WLPaginatedSet, PaginatedRequest;

@protocol WLPaginatedSetDelegate <WLSetDelegate>

@optional
- (void)paginatedSetDidStartLoading:(WLPaginatedSet* __nonnull)set;

- (void)paginatedSetDidFinishLoading:(WLPaginatedSet* __nonnull)set;

@end

@interface WLPaginatedSet : WLSet

@property (nonatomic) BOOL completed;

@property (strong, nonatomic) PaginatedRequest* __nullable request;

@property (nonatomic) NSMutableIndexSet* __nonnull loadingTypes;

@property (nonatomic, weak) id <WLPaginatedSetDelegate> __nullable delegate;

@property (strong, nonatomic) NSString * __nonnull paginationDateKeyPath;

+ (instancetype __nonnull)setWithEntries:(NSSet* __nullable)entries request:(PaginatedRequest* __nullable)request;

+ (instancetype __nonnull)setWithRequest:(PaginatedRequest* __nullable)request;

- (void)configureRequest:(PaginatedRequest* __nullable)request;

- (NSDate* __nullable)newerPaginationDate;

- (NSDate* __nullable)olderPaginationDate;

- (void)fresh:(ArrayBlock __nullable)success failure:(FailureBlock __nullable)failure;

- (void)newer:(ArrayBlock __nullable)success failure:(FailureBlock __nullable)failure;

- (void)older:(ArrayBlock __nullable)success failure:(FailureBlock __nullable)failure;

- (void)handleResponse:(NSArray*  __nonnull)entries;

@end
