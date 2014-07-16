//
//  WLDeleteCandyRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDeleteCandyRequest.h"

@implementation WLDeleteCandyRequest

+ (NSString *)defaultMethod {
    return @"DELETE";
}

+ (instancetype)request:(WLCandy *)candy {
    WLDeleteCandyRequest* request = [WLDeleteCandyRequest request];
    request.candy = candy;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/candies/%@", self.candy.wrap.identifier, self.candy.identifier];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    [self.candy remove];
    return nil;
}

@end
