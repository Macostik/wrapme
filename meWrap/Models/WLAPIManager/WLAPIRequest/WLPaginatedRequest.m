//
//  WLPaginatedRequest.m
//  meWrap
//
//  Created by Ravenpod on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest.h"

@implementation WLPaginatedRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        [self parametrize:^(WLPaginatedRequest *request, NSMutableDictionary *parameters) {
            WLPaginatedRequestType type = request.type;
            if (type == WLPaginatedRequestTypeNewer) {
                [parameters setObject:@(request.newer.timestamp) forKey:@"offset_x_in_epoch"];
            } else if (type == WLPaginatedRequestTypeOlder) {
                [parameters setObject:@(request.newer.timestamp) forKey:@"offset_x_in_epoch"];
                [parameters setObject:@(request.older.timestamp) forKey:@"offset_y_in_epoch"];
            }
            if (request.sameDay) {
                [parameters setObject:@(request.sameDay) forKey:@"same_day"];
            }
        }];
    }
    return self;
}

- (id)fresh:(ArrayBlock)success failure:(FailureBlock)failure {
    self.type = WLPaginatedRequestTypeFresh;
    return [self send:success failure:failure];
}

- (id)newer:(ArrayBlock)success failure:(FailureBlock)failure {
    self.type = WLPaginatedRequestTypeNewer;
    return [self send:success failure:failure];
}

- (id)older:(ArrayBlock)success failure:(FailureBlock)failure {
    self.type = WLPaginatedRequestTypeOlder;
    return [self send:success failure:failure];
}

- (id)send:(ArrayBlock)success failure:(FailureBlock)failure {
    return [super send:success failure:failure];
}

@end
