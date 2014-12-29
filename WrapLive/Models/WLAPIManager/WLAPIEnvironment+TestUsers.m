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

@implementation WLAPIEnvironment (TestUsers)

- (void)testUsers:(void (^)(NSArray *))completion {
    if (completion) {
        NSMutableArray *groups = [NSMutableArray array];
        for (NSDictionary *item in [NSArray resourcePropertyListNamed:self.testUsersPropertyListName]) {
            NSMutableDictionary* group = [item mutableCopy];
            NSMutableArray *authorizations = [NSMutableArray array];
            for (NSDictionary *item in [group objectForKey:@"users"]) {
                WLAuthorization* authorization = [[WLAuthorization alloc] init];
                authorization.deviceUID = [item objectForKey:@"deviceUID"];
                authorization.countryCode = [item objectForKey:@"countryCode"];
                authorization.phone = [item objectForKey:@"phone"];
                authorization.email = [item objectForKey:@"email"];
                authorization.activationCode = [item objectForKey:@"activationCode"];
                authorization.password = [item objectForKey:@"password"];
                [authorizations addObject:authorization];
            }
            group[@"users"] = authorizations;
            [groups addObject:group];
        }
        completion(groups);
    }
}

@end
