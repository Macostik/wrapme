//
//  WLRecentCandiesRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLRecentContributionsRequest.h"
#import "WLCandy+Extended.h"

@implementation WLRecentContributionsRequest

+ (NSString *)defaultMethod {
    return @"GET";
}

- (NSString *)path {
    return @"candies";
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    [parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
    return [super configure:parameters];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    NSArray *candies = [response.data arrayForKey:WLCandiesKey];
    NSMutableOrderedSet *contributions = [NSMutableOrderedSet orderedSet];
    for (NSDictionary *candyData in candies) {
        NSArray *comments = [candyData arrayForKey:WLCommentsKey];
        WLCandy *candy = [WLCandy API_entry:candyData];
        candy.wrap.name = candyData[WLWrapNameKey];
        if (comments.nonempty) {
            [contributions addObject:[WLComment API_entry:[comments firstObject] relatedEntry:candy]];
        } else {
            [contributions addObject:candy];
        }
    }
    return contributions;
}

@end
