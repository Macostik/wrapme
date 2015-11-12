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
@import WatchConnectivity;

@implementation WLExtensionManager

+ (void)performRequest:(ExtensionRequest*)request completionHandler:(void (^)(ExtensionResponse *response))completionHandler {
    SEL selector = NSSelectorFromString(request.action);
    if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:request withObject:completionHandler];
#pragma clang diagnostic pop
    } else {
        if (completionHandler) completionHandler([ExtensionResponse failure:@"Action is not supported."]);
    }
}

+ (void)postComment:(ExtensionRequest*)request completionHandler:(void (^)(ExtensionResponse *response))completionHandler {
    NSString *candyIdentifier = request.userInfo[WLCandyUIDKey];
    NSString *text = request.userInfo[@"text"];
    if ([Candy entryExists:candyIdentifier]) {
        Candy *candy = [Candy entry:candyIdentifier];
        [candy uploadComment:text success:^(Comment *comment) {
            completionHandler([ExtensionResponse success:nil]);
        } failure:^(NSError *error) {
            completionHandler([ExtensionResponse failure:error.localizedDescription]);
        }];
    } else {
        completionHandler([ExtensionResponse failure:@"Photo isn't available."]);
    }
}

+ (void)postMessage:(ExtensionRequest*)request completionHandler:(void (^)(ExtensionResponse *response))completionHandler {
    NSString *wrapIdentifier = request.userInfo[WLWrapUIDKey];
    NSString *text = request.userInfo[@"text"];
    if ([Wrap entryExists:wrapIdentifier]) {
        Wrap *wrap = [Wrap entry:wrapIdentifier];
        [wrap uploadMessage:text success:^(Message *message) {
            completionHandler([ExtensionResponse success:nil]);
        } failure:^(NSError *error) {
            completionHandler([ExtensionResponse failure:error.localizedDescription]);
        }];
    } else {
        completionHandler([ExtensionResponse failure:@"Wrap isn't available."]);
    }
}

+ (void)handleNotification:(ExtensionRequest*)request completionHandler:(void (^)(ExtensionResponse *response))completionHandler {
    [[WLNotificationCenter defaultCenter] handleRemoteNotification:request.userInfo success:^(WLNotification *notification) {
        Entry *entry = notification.entry;
        if (entry) {
            completionHandler([ExtensionResponse success:nil userInfo:@{@"entry":[entry serializeReference]}]);
        } else {
            completionHandler([ExtensionResponse failure:@"No data"]);
        }
    } failure:^(NSError *error) {
        completionHandler([ExtensionResponse failure:error.localizedDescription]);
    }];
}

+ (void)dataSync:(ExtensionRequest*)request completionHandler:(void (^)(ExtensionResponse *response))completionHandler {
    if ([[UIDevice currentDevice] systemVersionSince:@"9"]) {
        if ([WCSession defaultSession].paired && [WCSession defaultSession].watchAppInstalled) {
            for (NSPersistentStore *store in EntryContext.sharedContext.persistentStoreCoordinator.persistentStores) {
                NSURL *url = store.URL;
                if ([url checkResourceIsReachableAndReturnError:nil]) {
                    [[WCSession defaultSession] transferFile:url metadata:nil];
                }
            }
        }
    }
    if (completionHandler) completionHandler([ExtensionResponse success:nil]);
}

@end
