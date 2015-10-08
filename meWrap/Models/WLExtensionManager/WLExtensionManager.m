//
//  WLExtensionManager.m
//  meWrap
//
//  Created by Sergey Maximenko on 10/8/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import "WLExtensionManager.h"
#import "WLEntry+WLUploadingQueue.h"
#import "WLNotificationCenter.h"
#import "WLNotification.h"

@implementation WLExtensionManager

+ (void)performRequest:(WLExtensionRequest*)request completionHandler:(void (^)(WLExtensionResponse *response))completionHandler {
    SEL selector = NSSelectorFromString(request.action);
    if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:request withObject:completionHandler];
#pragma clang diagnostic pop
    } else {
        if (completionHandler) completionHandler([WLExtensionResponse failureWithMessage:@"Action is not supported."]);
    }
}

+ (void)postComment:(WLExtensionRequest*)request completionHandler:(void (^)(WLExtensionResponse *response))completionHandler {
    NSString *candyIdentifier = request.userInfo[WLCandyUIDKey];
    NSString *text = request.userInfo[@"text"];
    if ([WLCandy entryExists:candyIdentifier]) {
        WLCandy *candy = [WLCandy entry:candyIdentifier];
        [candy uploadComment:text success:^(WLComment *comment) {
            completionHandler([WLExtensionResponse success]);
        } failure:^(NSError *error) {
            completionHandler([WLExtensionResponse failureWithMessage:error.localizedDescription]);
        }];
    } else {
        completionHandler([WLExtensionResponse failureWithMessage:@"Photo isn't available."]);
    }
}

+ (void)postMessage:(WLExtensionRequest*)request completionHandler:(void (^)(WLExtensionResponse *response))completionHandler {
    NSString *wrapIdentifier = request.userInfo[WLWrapUIDKey];
    NSString *text = request.userInfo[@"text"];
    if ([WLWrap entryExists:wrapIdentifier]) {
        WLWrap *wrap = [WLWrap entry:wrapIdentifier];
        [wrap uploadMessage:text success:^(WLMessage *message) {
            completionHandler([WLExtensionResponse success]);
        } failure:^(NSError *error) {
            completionHandler([WLExtensionResponse failureWithMessage:error.localizedDescription]);
        }];
    } else {
        completionHandler([WLExtensionResponse failureWithMessage:@"Wrap isn't available."]);
    }
}

+ (void)handleNotification:(WLExtensionRequest*)request completionHandler:(void (^)(WLExtensionResponse *response))completionHandler {
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:request.userInfo success:^(WLNotification *notification) {
        WLEntry *entry = notification.entry;
        if (entry) {
            completionHandler([WLExtensionResponse successWithUserInfo:@{@"entry":[entry dictionaryRepresentation]}]);
        } else {
            completionHandler([WLExtensionResponse failureWithMessage:@"No data"]);
        }
    } failure:^(NSError *error) {
        completionHandler([WLExtensionResponse failureWithMessage:error.localizedDescription]);
    }];
}

@end
