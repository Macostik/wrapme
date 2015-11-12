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

@protocol WLPaginatedSetDelegate <WLSetDelegate>

@optional
- (void)paginatedSetDidStartLoading:(WLPaginatedSet* __nonnull)set;

- (void)paginatedSetDidFinishLoading:(WLPaginatedSet* __nonnull)set;

@end

@interface WLPaginatedSet : WLSet

@property (nonatomic) BOOL completed;

@property (strong, nonatomic) WLPaginatedRequest* __nullable request;

@property (nonatomic) NSMutableIndexSet* __nonnull loadingTypes;

@property (nonatomic, weak) id <WLPaginatedSetDelegate> __nullable delegate;

@property (strong, nonatomic) NSString * __nonnull paginationDateKeyPath;

+ (instancetype __nonnull)setWithEntries:(NSSet* __nullable)entries request:(WLPaginatedRequest* __nullable)request;

+ (instancetype __nonnull)setWithRequest:(WLPaginatedRequest* __nullable)request;

- (void)configureRequest:(WLPaginatedRequest* __nullable)request;

- (NSDate* __nullable)newerPaginationDate;

- (NSDate* __nullable)olderPaginationDate;

- (void)fresh:(WLArrayBlock __nullable)success failure:(WLFailureBlock __nullable)failure;

- (void)newer:(WLArrayBlock __nullable)success failure:(WLFailureBlock __nullable)failure;

- (void)older:(WLArrayBlock __nullable)success failure:(WLFailureBlock __nullable)failure;

- (void)handleResponse:(NSArray*  __nonnull)entries;

@end
