//
//  WLWrapRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWrapRequest.h"
#import "WLWrapBroadcaster.h"

@implementation WLWrapRequest

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@", self.wrap.identifier];
}

+ (instancetype)request:(WLWrap *)wrap {
    WLWrapRequest* request = [WLWrapRequest request];
    request.wrap = wrap;
    return request;
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
	[parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
    [parameters trySetObject:self.contentType forKey:@"pick"];
    if (self.type == WLPaginatedRequestTypeNewer && self.newer) {
        [parameters trySetObject:@"newer_than" forKey:@"condition"];
        [parameters trySetObject:@(self.newer.timestamp) forKey:@"offset"];
    } else if (self.type == WLPaginatedRequestTypeOlder && self.older) {
        [parameters trySetObject:@"older_than" forKey:@"condition"];
        [parameters trySetObject:@(self.older.timestamp) forKey:@"offset"];
    }
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    NSMutableOrderedSet* oldCandies = [self.wrap.candies mutableCopy];
    [self.wrap update:response.data[@"wrap"]];
    NSMutableOrderedSet* newCandies = [self.wrap.candies mutableCopy];
    [newCandies minusOrderedSet:oldCandies];
    return newCandies;
}

- (void)handleFailure:(NSError *)error {
    if (self.wrap.uploaded && error.isContentUnavaliable) {
        [self.wrap remove];
        self.wrap = nil;
    }
    [super handleFailure:error];
}

- (BOOL)isContentType:(NSString *)contentType {
    return [self.contentType isEqualToString:contentType];
}

@end
