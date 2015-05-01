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

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *label;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *image;

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
        [self.label setText:nil];
        [self.image setImage:nil];
        [entry recursivelyFetchIfNeeded:^ {
            weakSelf.image.url = entry.picture.small;
            [weakSelf.label setText:remoteNotification[@"aps"][@"alert"]];
            completionHandler(WKUserNotificationInterfaceTypeCustom);
        } failure:^(NSError *error) {
            completionHandler(WKUserNotificationInterfaceTypeDefault);
        }];
    } else {
        completionHandler(WKUserNotificationInterfaceTypeDefault);
    }
}

@end



