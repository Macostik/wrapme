//
//  WLAPIConfiguration.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIEnvironment.h"
#import "NSString+Additions.h"

@implementation WLAPIEnvironment

+ (NSDictionary*)environments {
    return @{WLAPIEnvironmentLocal:@{@"endpoint":@"http://0.0.0.0:3000/api",
                                           @"version":@"6",
                                           @"url_scheme":@"wrapliveadhoc"},
             WLAPIEnvironmentQA:@{@"endpoint":@"https://qa-api.mojimojiapp.com/api",
                                  @"version":@"6",
                                  @"url_scheme":@"wrapliveadhoc"},
             WLAPIEnvironmentProduction:@{@"endpoint":@"https://prd-api.mojimojiapp.com/api",
                                          @"version":@"6",
                                          @"url_scheme":@"wraplive"}};
}

+ (instancetype)environmentNamed:(NSString *)name {
    if (!name.nonempty) {
        name = WLAPIEnvironmentProduction;
    }
    NSDictionary* dictionary = [[self environments] objectForKey:name];
    WLAPIEnvironment* environment = [[WLAPIEnvironment alloc] init];
    environment.endpoint = dictionary[@"endpoint"];
    environment.version = dictionary[@"version"];
    environment.urlScheme = dictionary[@"url_scheme"];
    environment.name = name;
    return environment;
}

- (BOOL)isProduction {
    return [self.name isEqualToString:WLAPIEnvironmentProduction];
}

@end
