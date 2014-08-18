//
//  WLPaginatedRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

typedef NS_ENUM(NSUInteger, WLPaginatedRequestType) {
    WLPaginatedRequestTypeFresh,
    WLPaginatedRequestTypeNewer,
    WLPaginatedRequestTypeOlder
};

@interface WLPaginatedRequest : WLAPIRequest

@property (strong, nonatomic) NSDate* newer;

@property (strong, nonatomic) NSDate* older;

@property (nonatomic) BOOL sameDay;

@property (nonatomic) WLPaginatedRequestType type;

- (id)fresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)send:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

@end
