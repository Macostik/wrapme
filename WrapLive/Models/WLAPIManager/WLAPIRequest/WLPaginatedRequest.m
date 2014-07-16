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
    [parameters setObject:@(self.sameDay) forKey:@"same_day"];
    return parameters;
}

@end
