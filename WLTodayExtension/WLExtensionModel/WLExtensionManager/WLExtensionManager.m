//
//  WLExtensionManager.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/2/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLExtensionManager.h"
#import "WLPost.h"
#import "WLEntryKeys.h"
#import "WLCryptographer.h"

static NSString* WLAPIEnvironmentDevelopment = @"development";
static NSString* WLAPIEnvironmentQA = @"qa";
static NSString* WLAPIEnvironmentBeta = @"beta";
static NSString* WLAPIEnvironmentProduction = @"production";
static NSString *const WLAPIVersion = @"5";
static NSString *const WLUserDefaultsExtensionKey = @"group.com.ravenpod.wraplive";
static NSString *const WLExtensionWrapKey = @"WLExtansionWrapKey";

@interface WLExtensionManager ()


@end

@implementation WLExtensionManager

+ (instancetype)instance {
    static WLExtensionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *environmentString = [[self parseUserDefaults] valueForKey:WLEnvironment];
        NSString *WLAPIBaseURLString = [self baseUrl:environmentString];
        manager = [[WLExtensionManager alloc] initWithBaseURL:[NSURL URLWithString:WLAPIBaseURLString]];
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        NSString* acceptHeader = [NSString stringWithFormat:@"application/vnd.ravenpod+json;version=%@", WLAPIVersion];
        [manager.requestSerializer setValue:acceptHeader forHTTPHeaderField:@"Accept"];
    });
    
    return manager;
}

+ (NSString *)propertyListNameForEnvironment:(NSString*)environment {
    if ([environment isEqualToString:WLAPIEnvironmentQA]) {
        return @"WLAPIEnvironmentQA";
    } else if ([environment isEqualToString:WLAPIEnvironmentBeta]) {
        return @"WLAPIEnvironmentBeta";
    } else if ([environment isEqualToString:WLAPIEnvironmentProduction]) {
        return @"WLAPIEnvironmentProduction";
    }
    return @"WLAPIEnvironmentDevelopment";
}

+ (NSString *)baseUrl:(NSString *)name {
    NSString* path = [[NSBundle mainBundle] pathForResource:[self propertyListNameForEnvironment:name] ofType:@"plist"];
    NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    return dictionary[@"endpoint"];
}

+ (NSURLSessionDataTask *)postsHandlerBlock:(void (^)(NSArray *posts, NSError *error))block {
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
    return [[WLExtensionManager instance] GET:WLCandiesKey
                                   parameters:parameters
                                      success:^(NSURLSessionDataTask * __unused task, id JSON) {
                                          NSDictionary *responseData = [JSON valueForKeyPath:@"data"];
                                          NSArray *postsContent = [responseData valueForKey:WLCandiesKey];
                                          NSMutableArray *mutablePosts = [NSMutableArray arrayWithCapacity:[postsContent count]];
                                          if ([postsContent count]) {
                                              for (NSDictionary *attributes in postsContent) {
                                                  WLPost *post = [WLPost  initWithAttributes:attributes];
                                                  [mutablePosts addObject:post];
                                              }
                                          }
                                          
                                          if (block) {
                                              block([NSArray arrayWithArray:mutablePosts], nil);
                                          }
                                      } failure:^(NSURLSessionDataTask *__unused task, NSError *error) {
                                          if (block) {
                                              block([NSArray array], error);
                                          }
                                      }];
}

+ (NSURLSessionDataTask *)signInHandlerBlock:(void(^)(NSURLSessionDataTask *task, id responseObject))success
                                     failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    NSMutableDictionary *parameters = [self parseUserDefaults].mutableCopy;
    NSString *password = [WLCryptographer decrypt:[parameters objectForKey:WLPasswordKey]];
    [parameters setObject:password forKey:WLPasswordKey];
    return [[WLExtensionManager instance] POST:@"users/sign_in"
                                    parameters:parameters
                                       success:^(NSURLSessionDataTask *task, id responseObject) {
            success(task, responseObject);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failure(task, error);
    }];
}

+ (NSDictionary *)parseUserDefaults {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:WLUserDefaultsExtensionKey];
    return [userDefaults objectForKey:WLExtensionWrapKey];
}

@end
