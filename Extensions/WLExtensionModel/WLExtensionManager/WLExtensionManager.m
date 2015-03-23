//
//  WLExtensionManager.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/2/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLExtensionManager.h"
#import "WLExtensionEvent.h"
#import "WLEntryKeys.h"
#import "WLCryptographer.h"
#import "WLAPIEnvironment.h"
#import "NSUserDefaults+WLAppGroup.h"
#import "WLAuthorization.h"
#import "NSDictionary+Extended.h"

@interface WLExtensionManager ()

@end

@implementation WLExtensionManager

+ (instancetype)instance {
    static WLExtensionManager *manager = nil;
    static dispatch_once_t onceToken;
    NSString *environmentString = [[NSUserDefaults appGroupUserDefaults] objectForKey:WLAppGroupEnvironment];
    if (environmentString != nil) {
        dispatch_once(&onceToken, ^{
            WLAPIEnvironment *environment = [WLAPIEnvironment configuration:environmentString];
            manager = [[WLExtensionManager alloc] initWithBaseURL:[NSURL URLWithString:environment.endpoint]];
            manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
            NSString* acceptHeader = [NSString stringWithFormat:@"application/vnd.ravenpod+json;version=%@", environment.version];
            [manager.requestSerializer setValue:acceptHeader forHTTPHeaderField:@"Accept"];
        });
    }
    return manager;
}

- (NSURLSessionDataTask *)posts:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    return [[WLExtensionManager instance] GET:WLCandiesKey
                                   parameters:@{@"tz":[[NSTimeZone localTimeZone] name]}
                                      success:^(NSURLSessionDataTask * __unused task, NSDictionary *JSON) {
                                          NSArray *postsContent = [[JSON dictionaryForKey:@"data"] arrayForKey:WLCandiesKey];
                                          NSMutableArray *posts = [NSMutableArray arrayWithCapacity:[postsContent count]];
                                          if ([postsContent count]) {
                                              for (NSDictionary *attributes in postsContent) {
                                                  WLExtensionEvent *post = [WLExtensionEvent postWithAttributes:attributes];
                                                  [posts addObject:post];
                                              }
                                          }
                                          
                                          if (success) {
                                              success([NSArray arrayWithArray:posts]);
                                          }
                                      } failure:^(NSURLSessionDataTask *__unused task, NSError *error) {
                                          NSHTTPURLResponse* response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
                                          if (response && response.statusCode == WLAuthorizedError)
                                              [self signIn:^{
                                                  [self posts:success failure:failure];
                                              } failure:failure];
                                          if (failure) failure(error);
                                      }];
}

- (NSURLSessionDataTask *)signIn:(WLBlock)success failure:(WLFailureBlock)failure {
    NSData *authorizationData = [[NSUserDefaults appGroupUserDefaults] objectForKey:WLAppGroupEncryptedAuthorization];
    if (!authorizationData) {
        failure(nil);
        return nil;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    WLAuthorization *authorization = [WLAuthorization unarchive:[WLCryptographer decryptData:authorizationData]];
    [authorization configureParameters:parameters useUncorfirmedEmail:NO];
    return [[WLExtensionManager instance] POST:@"users/sign_in" parameters:parameters success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
        NSInteger code = [responseObject integerForKey:@"return_code"];
        if (code == WLNoError) {
            self.authorized = YES;
            if (success) success();
        } else if (failure) {
            failure([NSError errorWithDomain:NSURLErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:[responseObject stringForKey:@"message"]}]);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) failure(error);
    }];
}

@end
