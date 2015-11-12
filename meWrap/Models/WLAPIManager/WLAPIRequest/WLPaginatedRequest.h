//
//  WLPaginatedRequest.h
//  meWrap
//
//  Created by Ravenpod on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"

typedef NS_ENUM(NSUInteger, WLPaginatedRequestType) {
    WLPaginatedRequestTypeFresh,
    WLPaginatedRequestTypeNewer,
    WLPaginatedRequestTypeOlder
};

@interface WLPaginatedRequest : WLAPIRequest

@property (strong, nonatomic) NSDate*  __nullable newer;

@property (strong, nonatomic) NSDate*  __nullable older;

@property (nonatomic) BOOL sameDay;

@property (nonatomic) WLPaginatedRequestType type;

- (id __nullable)fresh:(WLArrayBlock __nullable)success failure:(WLFailureBlock __nullable)failure;

- (id __nullable)newer:(WLArrayBlock __nullable)success failure:(WLFailureBlock __nullable)failure;

- (id __nullable)older:(WLArrayBlock __nullable)success failure:(WLFailureBlock __nullable)failure;

- (id __nullable)send:(WLArrayBlock __nullable)success failure:(WLFailureBlock __nullable)failure;

@end
