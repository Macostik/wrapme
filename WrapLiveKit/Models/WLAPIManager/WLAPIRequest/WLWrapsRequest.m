//
//  WLWrapsRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWrapsRequest.h"

@implementation WLWrapsRequest

- (NSString *)path {
    return @"wraps";
}

- (id)objectInResponse:(WLAPIResponse *)response {
    NSOrderedSet* wraps = [WLWrap API_entries:[response.data arrayForKey:@"wraps"]];
    if (wraps.nonempty) {
        [[WLUser currentUser] addWraps:wraps];
        id candies = [response.data arrayForKey:@"recent_candies"];
        if (candies) {
            WLWrap* wrap = [wraps firstObject];
            [wrap addCandies:[WLCandy API_entries:candies relatedEntry:wrap]];
        }
    }
    return wraps;
}

@end
