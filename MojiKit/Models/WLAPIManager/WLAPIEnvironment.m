//
//  WLAPIConfiguration.m
//  moji
//
//  Created by Ravenpod on 9/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIEnvironment.h"
#import "NSString+Additions.h"
#import "WLAuthorization.h"
#import "NSPropertyListSerialization+Shorthand.h"
#import "NSDictionary+Extended.h"

@implementation WLAPIEnvironment

+ (instancetype)currentEnvironment {
    static id instance = nil;
    if (instance == nil) {
        instance = [self environmentNamed:ENV];
    }
    return instance;
}

+ (NSDictionary*)environments {
    return @{WLAPIEnvironmentLocal:@{@"endpoint":@"http://0.0.0.0:3000/api",
                                           @"version":@"7"},
             WLAPIEnvironmentQA:@{@"endpoint":@"https://qa-api.mojimojiapp.com/api",
                                  @"version":@"7"},
             WLAPIEnvironmentProduction:@{@"endpoint":@"https://prd-api.mojimojiapp.com/api",
                                          @"version":@"7"}};
}

+ (instancetype)environmentNamed:(NSString *)name {
    if (!name.nonempty) {
        name = WLAPIEnvironmentProduction;
    }
    NSDictionary* dictionary = [[self environments] objectForKey:name];
    WLAPIEnvironment* environment = [[WLAPIEnvironment alloc] init];
    environment.endpoint = dictionary[@"endpoint"];
    environment.version = dictionary[@"version"];
    environment.name = name;
    WLLog(@"MOJI", @"API environment initialized", dictionary);
    return environment;
}

- (BOOL)isProduction {
    return [self.name isEqualToString:WLAPIEnvironmentProduction];
}

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
