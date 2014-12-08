//
//  WLRemoteObjectHandler.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLRemoteObjectHandler.h"
#import "WLEntry.h"
#import "WLNavigation.h"
#import "WLNotification.h"
#import "NSError+WLAPIManager.h"
#import "WLNotificationCenter.h"
#import "WLAPIManager.h"

@interface WLRemoteObjectHandler ()

@property (strong, nonatomic) WLNotification *pendingRemoteNotification;
@end

@implementation WLRemoteObjectHandler

+ (void)presentViewControllerByUrlExtension:(NSURL *)url {
    NSMutableString *urlString = [[url query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding].mutableCopy;
    NSRange range = [urlString rangeOfString:@"uid="];
    NSString *candyID = [urlString substringFromIndex:range.location + range.length];
    WLCandy *candy = [WLCandy entry:candyID];
    if (candy.valid) {
        [candy presentViewControllerWithoutLostData];
    }
}

- (void)handleRemoteObject:(NSDictionary *)data success:(WLBlock)success failure:(WLFailureBlock)failure {
    WLNotification* notification = [WLNotification notificationWithData:data];
    if (notification) {
        self.pendingRemoteNotification = notification;
        if (success) success();
    } else if (failure)  {
        failure([NSError errorWithDescription:@"Data in remote notification is not valid (inactive)."]);
    }
}

- (void)addReceiver:(id)receiver {
    if (self.pendingRemoteNotification.targetEntry.fetched && [receiver respondsToSelector:@selector(broadcaster:didReceiveRemoteObject:)]) {
        [receiver broadcaster:self didReceiveRemoteObject:self.pendingRemoteNotification];
    }
}

@end
