//
//  WLWKContainingApplicationContext.m
//  meWrap
//
//  Created by Ravenpod on 6/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKParentApplicationContext.h"
#import <WatchKit/WatchKit.h>

@implementation WLWKParentApplicationContext

+ (void)performAction:(SEL)action success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    [self performAction:action parameters:nil success:success failure:failure];
}

+ (void)performAction:(SEL)action parameters:(NSDictionary*)parameters success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    WLExtensionRequest *request = [WLExtensionRequest requestWithAction:NSStringFromSelector(action) userInfo:parameters];
    [WKInterfaceController openParentApplication:[request serialize] reply:^(NSDictionary *replyInfo, NSError *error) {
        if (error) {
            if (failure) failure(error);
        } else  {
            WLExtensionResponse *response = [WLExtensionResponse deserialize:replyInfo];
            if (response.success) {
                if (success) success(response.userInfo);
            } else {
                if (failure) failure([NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:response.message}]);
            }
        }
    }];
}

@end

@implementation WLWKParentApplicationContext (DefinedActions)

+ (void)postMessage:(NSString *)text wrap:(NSString *)wrapIdentifier success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    [self performAction:@selector(postMessage:completionHandler:) parameters:@{WLWrapUIDKey:wrapIdentifier,@"text":text} success:success failure:failure];
}

+ (void)postComment:(NSString *)text candy:(NSString *)candyIdentifier success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    [self performAction:@selector(postComment:completionHandler:) parameters:@{WLCandyUIDKey:candyIdentifier,@"text":text} success:success failure:failure];
}

+ (void)handleNotification:(NSDictionary *)notification success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    [self performAction:@selector(handleNotification:completionHandler:) parameters:notification success:success failure:failure];
}

@end
