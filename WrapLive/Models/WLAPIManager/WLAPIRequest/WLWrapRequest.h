//
//  WLWrapRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest.h"

static NSString* WLWrapContentTypeRecent = @"recent_candies";
static NSString* WLWrapContentTypePaginated = @"paginated_by_date";

@interface WLWrapRequest : WLPaginatedRequest

@property (weak, nonatomic) WLWrap* wrap;

@property (nonatomic) NSString* contentType;

+ (instancetype)request:(WLWrap*)wrap;

- (BOOL)isContentType:(NSString*)contentType;

@end
