//
//  WLLeaveWrapRequest.m
//  WrapLive
//
//  Created by Yura Granchenko on 9/18/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLLeaveWrapRequest.h"

@implementation WLLeaveWrapRequest

+ (NSString *)defaultMethod {
    return @"DELETE";
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/leave", self.wrap.identifier];
}

+ (instancetype)request:(WLWrap *)wrap {
    WLLeaveWrapRequest* request = [WLLeaveWrapRequest request];
    request.wrap = wrap;
    return request;
}

@end
