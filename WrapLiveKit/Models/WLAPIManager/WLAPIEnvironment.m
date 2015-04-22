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
    return @{WLAPIEnvironmentDevelopment:@{@"endpoint":@"https://dev-api.wraplive.com/api",
                                           @"version":@"5"},
             WLAPIEnvironmentQA:@{@"endpoint":@"https://qa-api.wraplive.com/api",
                                  @"version":@"5"},
             WLAPIEnvironmentBeta:@{@"endpoint":@"https://qa-api.wraplive.com/api",
                                    @"version":@"5"},
             WLAPIEnvironmentProduction:@{@"endpoint":@"https://prd-api.wraplive.com/api",
                                          @"version":@"5"}};
}

+ (instancetype)environmentNamed:(NSString *)name {
    if (!name.nonempty) {
        name = WLAPIEnvironmentProduction;
    }
    NSDictionary* dictionary = [[self environments] objectForKey:name];
    WLAPIEnvironment* environment = [[WLAPIEnvironment alloc] init];
    environment.endpoint = dictionary[@"endpoint"];
    environment.version = dictionary[@"version"];
    environment.testUsersPropertyListName = dictionary[@"testUsersPropertyListName"];
    environment.name = name;
    return environment;
}

- (BOOL)isProduction {
    return [self.name isEqualToString:WLAPIEnvironmentProduction];
}

@end
