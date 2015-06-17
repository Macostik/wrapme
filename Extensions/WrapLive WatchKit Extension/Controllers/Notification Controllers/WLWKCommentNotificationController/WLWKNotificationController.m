//
//  NotificationController.m
//  WrapLive-Development WatchKit Extension
//
//  Created by Sergey Maximenko on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKNotificationController.h"
#import "WKInterfaceImage+WLImageFetcher.h"
#import "WLWKParentApplicationContext.h"

@interface WLWKNotificationController()

@property (weak, nonatomic) IBOutlet WKInterfaceImage *image;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *label;

@end

@implementation WLWKNotificationController

- (void)didReceiveRemoteNotification:(NSDictionary *)remoteNotification withCompletion:(void (^)(WKUserNotificationInterfaceType))completionHandler {
    __weak typeof(self)weakSelf = self;
    [self.image setImage:nil];
    [WLWKParentApplicationContext fetchNotification:remoteNotification success:^(NSDictionary *replyInfo) {
        WLEntry *entry = [WLEntry entryFromDictionaryRepresentation:replyInfo[@"entry"]];
        if (entry) {
            [weakSelf.label setText:[weakSelf alertMessageFromNotification:remoteNotification]];
            weakSelf.image.url = entry.picture.small;
            completionHandler(WKUserNotificationInterfaceTypeCustom);
        } else {
            completionHandler(WKUserNotificationInterfaceTypeDefault);
        }
    } failure:^(NSError *error) {
        completionHandler(WKUserNotificationInterfaceTypeDefault);
    }];
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



