//
//  WLUserRequest.m
//  WrapLive
//
//  Created by Yura Granchenko on 22/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUserRequest.h"

@implementation WLUserRequest

+ (instancetype)request:(WLUser *)user {
    WLUserRequest* request = [self request];
    request.user = user;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"users/%@", self.user.identifier];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLUser *user = self.user;
    NSDictionary* userData = response.data[@"user"];
    [user notifyOnUpdate:^(id object) {
        [user API_setup:userData];
    }];
    return user;
}

@end
