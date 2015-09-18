//
//  WLAPIConfiguration.m
//  meWrap
//
//  Created by Ravenpod on 9/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIEnvironment.h"
#import "NSString+Additions.h"
#import "WLAuthorization.h"
#import "NSBundle+Extended.h"
#import "NSDictionary+Extended.h"
#import "WLLogger.h"

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
                                     @"version":@"7",
                                     @"default_image_uri":@"https://d2rojtzyvje8rl.cloudfront.net/candies/image_attachments",
                                     @"default_avatar_uri":@"https://d2rojtzyvje8rl.cloudfront.net/users/avatars"},
             WLAPIEnvironmentQA:@{@"endpoint":@"https://qa-api.mewrap.me/api",
                                  @"version":@"7",
                                  @"default_image_uri":@"https://d2rojtzyvje8rl.cloudfront.net/candies/image_attachments",
                                  @"default_avatar_uri":@"https://d2rojtzyvje8rl.cloudfront.net/users/avatars"},
             WLAPIEnvironmentProduction:@{@"endpoint":@"https://prd-api.mewrap.me/api",
                                          @"version":@"7",
                                          @"default_image_uri":@"https://dhtwvi2qvu3d7.cloudfront.net/candies/image_attachments",
                                          @"default_avatar_uri":@"https://dhtwvi2qvu3d7.cloudfront.net/users/avatars"}};
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
    environment.defaultImageURI = dictionary[@"default_image_uri"];
    environment.defaultAvatarURI = dictionary[@"default_avatar_uri"];
    WLLog(@"meWrap - API environment initialized: %@", dictionary);
    return environment;
}

- (BOOL)isProduction {
    return [self.name isEqualToString:WLAPIEnvironmentProduction];
}

- (void)testUsers:(void (^)(NSArray *))completion {
    if (completion) {
        NSMutableArray *authorizations = [NSMutableArray array];
        for (NSDictionary *item in [[NSDictionary plist:@"WLTestUsers"] arrayForKey:self.name]) {
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
