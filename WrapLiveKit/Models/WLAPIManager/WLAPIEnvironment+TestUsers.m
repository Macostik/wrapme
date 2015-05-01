//
//  WLAPIEnvironment+TestUsers.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIEnvironment+TestUsers.h"
#import "WLAuthorization.h"
#import "NSPropertyListSerialization+Shorthand.h"
#import "NSDictionary+Extended.h"

@implementation WLAPIEnvironment (TestUsers)

- (void)testUsers:(void (^)(NSArray *))completion {
    if (completion) {
        NSMutableArray *authorizations = [NSMutableArray array];
        for (NSDictionary *item in [[NSDictionary resourcePropertyListNamed:@"WLTestUsers"] arrayForKey:self.name]) {
            WLAuthorization* authorization = [[WLAuthorization alloc] init];
            authorization.deviceUID = [item objectForKey:@"deviceUID"];
            authorization.countryCode = [item objectForKey:@"countryCode"];
            authorization.phone = [item objectForKey:@"phone"];
            authorization.email = [item objectForKey:@"email"];
            authorization.activationCode = [item objectForKey:@"activationCode"];
            authorization.password = [item objectForKey:@"password"];
            [authorizations addObject:authorization];
        }
        completion(authorizations);
    }
}

@end
