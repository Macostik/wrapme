//
//  WLPaginatedRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest.h"
#import "NSDate+Additions.h"

@implementation WLPaginatedRequest

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    WLPaginatedRequestType type = self.type;
    if (type == WLPaginatedRequestTypeNewer) {
        [parameters setObject:@(self.newer.timestamp) forKey:@"offset_x_in_epoch"];
    } else if (type == WLPaginatedRequestTypeOlder) {
        [parameters setObject:@(self.newer.timestamp) forKey:@"offset_x_in_epoch"];
        [parameters setObject:@(self.older.timestamp) forKey:@"offset_y_in_epoch"];
    }
    if (self.sameDay) {
        [parameters setObject:@(self.sameDay) forKey:@"same_day"];
    }
    return parameters;
}

- (id)fresh:(WLSetBlock)success failure:(WLFailureBlock)failure {
    self.type = WLPaginatedRequestTypeFresh;
    return [self send:success failure:failure];
}

- (id)newer:(WLSetBlock)success failure:(WLFailureBlock)failure {
    self.type = WLPaginatedRequestTypeNewer;
    return [self send:success failure:failure];
}

- (id)older:(WLSetBlock)success failure:(WLFailureBlock)failure {
    self.type = WLPaginatedRequestTypeOlder;
    return [self send:success failure:failure];
}

- (id)send:(WLSetBlock)success failure:(WLFailureBlock)failure {
    return [super send:success failure:failure];
}

@end
