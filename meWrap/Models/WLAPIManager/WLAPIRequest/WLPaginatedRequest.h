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

- (id __nullable)fresh:(ArrayBlock __nullable)success failure:(FailureBlock __nullable)failure;

- (id __nullable)newer:(ArrayBlock __nullable)success failure:(FailureBlock __nullable)failure;

- (id __nullable)older:(ArrayBlock __nullable)success failure:(FailureBlock __nullable)failure;

- (id __nullable)send:(ArrayBlock __nullable)success failure:(FailureBlock __nullable)failure;

@end
