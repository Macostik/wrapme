//
//  WLUpdateUserRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUpdateUserRequest.h"
#import "WLEntryNotifier.h"

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
    WLUser* user = self.user;
    self.filePath = user.picture.original;
    [parameters trySetObject:user.name forKey:@"name"];
    [parameters trySetObject:self.email forKey:@"email"];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLUser* user = self.user;
    NSDictionary* userData = response.data[@"user"];
    WLAuthorization* authorization = [WLAuthorization currentAuthorization];
    [authorization updateWithUserData:userData];
    [user notifyOnUpdate:^(id object) {
        [user API_setup:userData];
        [user setCurrent];
    }];
    return user;
}

@end
