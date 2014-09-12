//
//  WLWrapRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest.h"

static NSString* WLWrapContentTypeRecent = @"with_recent_candies";
static NSString* WLWrapContentTypePaginated = @"with_paginated_candies";

@interface WLWrapRequest : WLPaginatedRequest

@property (strong, nonatomic) WLWrap* wrap;

@property (nonatomic) NSInteger page;

@property (nonatomic) NSString* contentType;

+ (instancetype)request:(WLWrap*)wrap;

+ (instancetype)request:(WLWrap*)wrap page:(NSInteger)page;

- (BOOL)isContentType:(NSString*)contentType;

@end
