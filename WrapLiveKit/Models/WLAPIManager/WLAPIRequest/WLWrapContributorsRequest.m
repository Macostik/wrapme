//
//  WLWrapContributorsRequest.m
//  wrapLive
//
//  Created by Sergey Maximenko on 7/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapContributorsRequest.h"

@implementation WLWrapContributorsRequest

+ (instancetype)request:(WLWrap *)wrap {
    WLWrapContributorsRequest* request = [self request];
    request.wrap = wrap;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/contributors", self.wrap.identifier];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    NSSet *contributors = [WLUser API_entries:[response.data arrayForKey:WLContributorsKey]];
    if (self.wrap.valid && ![self.wrap.contributors isEqualToSet:contributors]) {
        self.wrap.contributors = contributors;
    }
    return contributors;
}

@end
