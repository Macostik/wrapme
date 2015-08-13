//
//  WLWKContainingApplicationContext.m
//  moji
//
//  Created by Ravenpod on 6/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKParentApplicationContext.h"
#import <WatchKit/WatchKit.h>

@implementation WLWKParentApplicationContext

+ (void)performAction:(NSString*)action success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    [self performAction:action parameters:nil success:success failure:failure];
}

+ (void)performAction:(NSString*)action parameters:(NSDictionary*)parameters success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    WLExtensionRequest *request = [WLExtensionRequest requestWithAction:action userInfo:parameters];
    [WKInterfaceController openParentApplication:[request serialize] reply:^(NSDictionary *replyInfo, NSError *error) {
        if (error) {
            if (failure) failure(error);
        } else  {
            WLExtensionResponse *response = [WLExtensionResponse deserialize:replyInfo];
            if (response.success) {
                if (success) success(response.userInfo);
            } else {
                if (failure) failure(WLError(response.message));
            }
        }
    }];
}

@end

@implementation WLWKParentApplicationContext (DefinedActions)

+ (void)requestAuthorization:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    [self performAction:@"authorization" success:success failure:failure];
}

+ (void)postMessage:(NSString *)text wrap:(NSString *)wrapIdentifier success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    [self performAction:@"post_chat_message" parameters:@{WLWrapUIDKey:wrapIdentifier,@"text":text} success:success failure:failure];
}

+ (void)postComment:(NSString *)text candy:(NSString *)candyIdentifier success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    [self performAction:@"post_comment" parameters:@{WLCandyUIDKey:candyIdentifier,@"text":text} success:success failure:failure];
}

@end
