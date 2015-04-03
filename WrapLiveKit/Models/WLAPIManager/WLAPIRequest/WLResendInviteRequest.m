//
//  WLResendInviteRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLResendInviteRequest.h"
#import "WLWrap.h"
#import "WLUser.h"

@implementation WLResendInviteRequest

+ (NSString *)defaultMethod {
    return @"POST";
}

+ (instancetype)request:(WLWrap *)wrap {
    WLResendInviteRequest* request = [WLResendInviteRequest request];
    request.wrap = wrap;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/resend_invitation", self.wrap.identifier];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    [parameters trySetObject:self.user.identifier forKey:WLUserUIDKey];
    return parameters;
}

@end
