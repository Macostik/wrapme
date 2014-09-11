//
//  WLUpdateUserRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUpdateUserRequest.h"

@implementation WLUpdateUserRequest

+ (NSString *)defaultMethod {
    return @"PUT";
}

- (NSString *)path {
    return @"users/update";
}

+ (instancetype)request:(WLUser *)user {
    WLUpdateUserRequest* request = [WLUpdateUserRequest request];
    request.user = user;
    return request;
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    self.filePath = self.user.picture.large;
    WLUser* user = self.user;
    [parameters trySetObject:user.name forKey:@"name"];
    [parameters trySetObject:self.email forKey:@"email"];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLUser* user = self.user;
    WLAuthorization* authorization = [WLAuthorization currentAuthorization];
    authorization.email = self.email;
    [authorization setCurrent];
    [user API_setup:response.data[@"user"]];
    [user setCurrent];
    return user;
}

@end
