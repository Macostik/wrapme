//
//  WLAPIConfiguration.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIEnvironment.h"
#import "WLAuthorization.h"
#import "NSPropertyListSerialization+Shorthand.h"
#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "NSError+WLAPIManager.h"

@implementation WLAPIEnvironment

+ (NSString*)propertyListNameForEnvironment:(NSString*)environment {
    if ([environment isEqualToString:WLAPIEnvironmentQA]) {
        return @"WLAPIEnvironmentQA";
    } else if ([environment isEqualToString:WLAPIEnvironmentBeta]) {
        return @"WLAPIEnvironmentBeta";
    } else if ([environment isEqualToString:WLAPIEnvironmentProduction]) {
        return @"WLAPIEnvironmentProduction";
    }
    return @"WLAPIEnvironmentDevelopment";
}

+ (instancetype)configuration:(NSString *)name {
    NSString* path = [[NSBundle mainBundle] pathForResource:[self propertyListNameForEnvironment:name] ofType:@"plist"];
    NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    WLAPIEnvironment* environment = [[WLAPIEnvironment alloc] init];
    environment.endpoint = dictionary[@"endpoint"];
    environment.version = dictionary[@"version"];
    environment.testUsersPropertyListName = dictionary[@"testUsersPropertyListName"];
    environment.useTestUsers = [dictionary[@"useTestUsers"] boolValue];
	environment.name = dictionary[@"environment"] ? : name;
    WLLog(environment.endpoint, @"API environment initialized", dictionary);
    return environment;
}

- (void)testUsers:(void (^)(NSArray *))completion {
    if (completion) {
        completion([[NSArray resourcePropertyListNamed:self.testUsersPropertyListName] map:^id(NSDictionary* item) {
            NSMutableDictionary* group = [item mutableCopy];
            group[@"users"] = [[group arrayForKey:@"users"] map:^id(NSDictionary* item) {
                WLAuthorization* authorization = [[WLAuthorization alloc] init];
                authorization.deviceUID = [item objectForKey:@"deviceUID"];
                authorization.countryCode = [item objectForKey:@"countryCode"];
                authorization.phone = [item objectForKey:@"phone"];
                authorization.email = [item objectForKey:@"email"];
                authorization.activationCode = [item objectForKey:@"activationCode"];
                authorization.password = [item objectForKey:@"password"];
                return authorization;
            }];
            return group;
        }]);
    }
}

- (BOOL)isProduction {
    return [self.name isEqualToString:WLAPIEnvironmentProduction];
}

@end
