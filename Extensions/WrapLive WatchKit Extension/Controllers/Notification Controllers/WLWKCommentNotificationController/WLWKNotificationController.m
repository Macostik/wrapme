//
//  NotificationController.m
//  moji-Development WatchKit Extension
//
//  Created by Ravenpod on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKNotificationController.h"
#import "WKInterfaceImage+WLImageFetcher.h"
#import "WLWKParentApplicationContext.h"

@interface WLWKNotificationController()

@property (weak, nonatomic) IBOutlet WKInterfaceImage *image;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *alertLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;

@end

@implementation WLWKNotificationController

- (void)didReceiveRemoteNotification:(NSDictionary *)remoteNotification withCompletion:(void (^)(WKUserNotificationInterfaceType))completionHandler {
    __weak typeof(self)weakSelf = self;
    [self.image setImage:nil];
    [weakSelf.alertLabel setText:[weakSelf alertMessageFromNotification:remoteNotification]];
    [weakSelf.titleLabel setText:[weakSelf titleMessageFromNotification:remoteNotification]];
    [WLWKParentApplicationContext fetchNotification:remoteNotification success:^(NSDictionary *replyInfo) {
        WLEntry *entry = [WLEntry entryFromDictionaryRepresentation:replyInfo[@"entry"]];
        if (entry) {
            [[WLImageCache cache] fetchIdentifiers];
            weakSelf.image.url = entry.picture.small;
        } else {
            [weakSelf.image setHidden:YES];
        }
    } failure:^(NSError *error) {
    }];
    completionHandler(WKUserNotificationInterfaceTypeCustom);
}

- (NSString*)alertMessageFromNotification:(NSDictionary*)notification {
    id alert = notification[@"aps"][@"alert"];
    if ([alert isKindOfClass:[NSString class]]) {
        return alert;
    }
    NSString *localizedAlert = WLLS(alert[@"loc-key"]);
    NSArray *args = alert[@"loc-args"];
    if (args.count == 0) {
        return localizedAlert;
    }

    return [NSString stringWithFormat:localizedAlert, [args tryAt:0], [args tryAt:1],[args tryAt:2], nil];
}

- (NSString*)titleMessageFromNotification:(NSDictionary*)notification {
    id alert = notification[@"aps"][@"alert"];
    if ([alert isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *title = WLLS(alert[@"title-loc-key"]);
    NSArray *args = alert[@"title-loc-args"];
    if (args.count == 0) {
        return title;
    }
    
    return [NSString stringWithFormat:title, [args tryAt:0], [args tryAt:1],[args tryAt:2], nil];
}

@end



