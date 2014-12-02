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

static NSString * const WLAPIBaseURLString = @"https://dev-api.wraplive.com/api";
static NSString *const WLUserDefaultsExtensionKey = @"group.com.ravenpod.wraplive";
static NSString *const WLExtensionWrapKey = @"WLExtansionWrapKey";

@implementation WLExtensionManager

+ (instancetype)instance {
    static WLExtensionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WLExtensionManager alloc] initWithBaseURL:[NSURL URLWithString:WLAPIBaseURLString]];
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        NSString* acceptHeader = [NSString stringWithFormat:@"application/vnd.ravenpod+json;version=5"];
        [manager.requestSerializer setValue:acceptHeader forHTTPHeaderField:@"Accept"];
    });
    
    return manager;
}

+ (NSURLSessionDataTask *)postsHandlerBlock:(void (^)(NSArray *posts, NSError *error))block {
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
    return [[WLExtensionManager instance] GET:@"wraps/candies"
                                   parameters:parameters
                                      success:^(NSURLSessionDataTask * __unused task, id JSON) {
                                          NSArray *postsFromResponse = [JSON valueForKeyPath:@"data"];
                                          NSMutableArray *mutablePosts = [NSMutableArray arrayWithCapacity:[postsFromResponse count]];
                                          for (NSDictionary *attributes in postsFromResponse) {
                                              WLPost *post = [WLPost  initWithAttributes:attributes];
                                              [mutablePosts addObject:post];
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

+ (NSURLSessionDataTask *)signInHandlerBlock {
    NSMutableDictionary *parameters = [self parseUserDefaults].mutableCopy;
    NSString *password = [WLCryptographer decrypt:[parameters objectForKey:WLPasswordKey]];
    [parameters setObject:password forKey:WLPasswordKey];
    return [[WLExtensionManager instance] POST:@"users/sign_in" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
    
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
    
    }];
}

+ (NSDictionary *)parseUserDefaults {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:WLUserDefaultsExtensionKey];
    return [userDefaults objectForKey:WLExtensionWrapKey];

}

@end
