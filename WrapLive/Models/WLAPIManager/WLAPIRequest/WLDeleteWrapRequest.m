//
//  WLDeleteWrapRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDeleteWrapRequest.h"

@implementation WLDeleteWrapRequest

+ (NSString *)defaultMethod {
    return @"DELETE";
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@", self.wrap.identifier];
}

+ (instancetype)request:(WLWrap *)wrap {
    WLDeleteWrapRequest* request = [WLDeleteWrapRequest request];
    request.wrap = wrap;
    return request;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    [self.wrap remove];
    return nil;
}

@end
