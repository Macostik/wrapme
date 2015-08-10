//
//  WLAPIRequest+Wraps.h
//  moji
//
//  Created by Ravenpod on 7/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest.h"

static NSString* WLWrapContentTypeRecent = @"recent_candies";
static NSString* WLWrapContentTypePaginated = @"paginated_by_date";

@interface WLPaginatedRequest (Defined)

+ (instancetype)wraps:(NSString*)scope;

+ (instancetype)candies:(WLWrap*)wrap;

+ (instancetype)messages:(WLWrap*)wrap;

+ (instancetype)wrap:(WLWrap*)wrap contentType:(NSString*)contentType;

- (instancetype)candies:(WLWrap*)wrap;

@end
