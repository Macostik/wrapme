//
//  WLAPIRequest+Wraps.h
//  meWrap
//
//  Created by Ravenpod on 7/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest.h"

static NSString* WLWrapContentTypeRecent = @"recent_candies";
static NSString* WLWrapContentTypePaginated = @"paginated_by_date";

@class Wrap;

@interface WLPaginatedRequest (Defined)

+ (instancetype)wraps:(NSString*)scope;

+ (instancetype)candies:(Wrap *)wrap;

+ (instancetype)messages:(Wrap *)wrap;

+ (instancetype)wrap:(Wrap *)wrap contentType:(NSString*)contentType;

- (instancetype)candies:(Wrap *)wrap;

@end
