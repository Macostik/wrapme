//
//  WLCandyRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandyRequest.h"
#import "WLWrapBroadcaster.h"

@implementation WLCandyRequest

+ (instancetype)request:(WLCandy *)candy {
    WLCandyRequest* request = [WLCandyRequest request];
    request.candy = candy;
    return request;
}

- (NSString *)path {
    WLCandy* candy = self.candy;
    return candy.wrap ? [NSString stringWithFormat:@"wraps/%@/candies/%@", candy.wrap.identifier, candy.identifier] : [NSString stringWithFormat:@"entities/%@", candy.identifier];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    return [self.candy update:[response.data dictionaryForKey:@"candy"]];
}

- (void)handleFailure:(NSError *)error {
    if (self.candy.uploaded && error.isContentUnavaliable) {
        [self.candy remove];
        self.candy = nil;
    }
    [super handleFailure:error];
}

@end
