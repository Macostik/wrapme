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
    return [NSString stringWithFormat:@"wraps/%@/candies/%@", self.candy.wrap.identifier, self.candy.identifier];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    return [self.candy update:[response.data dictionaryForKey:@"candy"]];
}

- (void)handleFailure:(NSError *)error {
    if ([error.domain isEqualToString:WLErrorDomain] && error.code == WLAPIResponseCodeContentUnavaliable) {
        [self.candy remove];
        self.candy = nil;
    }
    [super handleFailure:error];
}

@end
