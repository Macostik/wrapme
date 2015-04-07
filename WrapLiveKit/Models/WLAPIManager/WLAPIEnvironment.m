//
//  WLAPIConfiguration.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIEnvironment.h"

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

+ (instancetype)environmentNamed:(NSString *)name {
    NSString* path = [[NSBundle mainBundle] pathForResource:[self propertyListNameForEnvironment:name] ofType:@"plist"];
    NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    WLAPIEnvironment* environment = [[WLAPIEnvironment alloc] init];
    environment.endpoint = dictionary[@"endpoint"];
    environment.version = dictionary[@"version"];
    environment.testUsersPropertyListName = dictionary[@"testUsersPropertyListName"];
    environment.useTestUsers = [dictionary[@"useTestUsers"] boolValue];
	environment.name = dictionary[@"environment"] ? : name;
    return environment;
}

- (BOOL)isProduction {
    return [self.name isEqualToString:WLAPIEnvironmentProduction];
}

@end
