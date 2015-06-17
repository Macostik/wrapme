//
//  NotificationController.m
//  WrapLive-Development WatchKit Extension
//
//  Created by Sergey Maximenko on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKNotificationController.h"
#import "WKInterfaceImage+WLImageFetcher.h"

@interface WLWKNotificationController()

@property (weak, nonatomic) IBOutlet WKInterfaceImage *image;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *label;

@end

@implementation WLWKNotificationController

- (void)didReceiveRemoteNotification:(NSDictionary *)remoteNotification withCompletion:(void (^)(WKUserNotificationInterfaceType))completionHandler {
    WLEntryNotification *notification = [WLEntryNotification notificationWithData:remoteNotification];
    if (!notification) {
        completionHandler(WKUserNotificationInterfaceTypeDefault);
        return;
    }
    WLEntry *entry = notification.targetEntry;
    if (entry) {
        __weak typeof(self)weakSelf = self;
        [self.image setImage:nil];
        [entry recursivelyFetchIfNeeded:^ {
            [weakSelf.label setText:[weakSelf alertMessageFromNotification:remoteNotification]];
            weakSelf.image.url = entry.picture.small;
            completionHandler(WKUserNotificationInterfaceTypeCustom);
        } failure:^(NSError *error) {
            completionHandler(WKUserNotificationInterfaceTypeDefault);
        }];
    } else {
        completionHandler(WKUserNotificationInterfaceTypeDefault);
    }
}

- (NSString*)alertMessageFromNotification:(NSDictionary*)notification {
    id alert = notification[@"aps"][@"alert"];
    if ([alert isKindOfClass:[NSString class]]) {
        return alert;
    }
    NSString *localizedAlert = WLLS(alert[@"loc-key"]);
    NSArray *arguments = alert[@"loc-args"];
    if (arguments.count == 0) {
        return localizedAlert;
    }

    NSString *result = [NSString stringWithFormat:localizedAlert, [arguments tryObjectAtIndex:0], [arguments tryObjectAtIndex:1],[arguments tryObjectAtIndex:2], nil];
    return result;
}

@end



