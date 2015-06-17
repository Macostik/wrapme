//
//  WLWKContainingApplicationContext.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKParentApplicationContext.h"
#import <WatchKit/WatchKit.h>

@implementation WLWKParentApplicationContext

+ (void)performAction:(NSString*)action success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    [self performAction:action parameters:nil success:success failure:failure];
}

+ (void)performAction:(NSString*)action parameters:(NSDictionary*)parameters success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    NSMutableDictionary *_parameters = [NSMutableDictionary dictionaryWithObject:action forKey:@"action"];
    [_parameters addEntriesFromDictionary:parameters];
    [WKInterfaceController openParentApplication:[_parameters copy] reply:^(NSDictionary *replyInfo, NSError *error) {
        if (error) {
            if (failure) failure(error);
        } else if ([replyInfo[@"success"] boolValue] == NO) {
            if (failure) failure(WLError(replyInfo[@"message"]));
        } else {
            if (success) success(replyInfo);
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

+ (void)fetchNotification:(NSDictionary *)notification success:(WLDictionaryBlock)success failure:(WLFailureBlock)failure {
    [self performAction:@"fetch_notification" parameters:@{@"notification":notification} success:success failure:failure];
}

@end
