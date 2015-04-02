//
//  WLCandiesRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandiesRequest.h"

@implementation WLCandiesRequest

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/candies", self.wrap.identifier];
}

+ (instancetype)request:(WLWrap *)wrap {
    WLCandiesRequest* request = [WLCandiesRequest request];
    request.wrap = wrap;
    return request;
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    [parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
    [parameters trySetObject:self.orderBy forKey:@"order_by"];
    return [super configure:parameters];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLWrap *wrap = self.wrap;
    if (wrap.valid) {
        NSOrderedSet* candies = [WLCandy API_entries:response.data[WLCandiesKey] relatedEntry:wrap];
        [wrap addCandies:candies];
        return candies;
    }
    return nil;
}

@end
