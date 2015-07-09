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

- (id)fresh:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (id)newer:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (id)older:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (id)send:(WLSetBlock)success failure:(WLFailureBlock)failure;

@end
