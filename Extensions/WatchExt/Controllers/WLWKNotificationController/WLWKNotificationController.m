//
//  NotificationController.m
//  meWrap-Development WatchKit Extension
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
    
    [self.alertLabel setText:[self alertMessageFromNotification:remoteNotification]];
    [self.titleLabel setText:[self titleMessageFromNotification:remoteNotification]];
    [WLWKParentApplicationContext handleNotification:remoteNotification success:^(NSDictionary *dictionary) {
        WLEntry *entry = [WLEntry entryFromDictionaryRepresentation:[dictionary dictionaryForKey:@"entry"]];
        if (entry) {
            [[WLImageCache cache] fetchIdentifiers];
            self.image.url = entry.picture.small;
        } else {
            [self.image setHidden:YES];
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
    NSString *localizedAlert = NSLocalizedString(alert[@"loc-key"], nil);
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
    NSString *title = NSLocalizedString(alert[@"title-loc-key"], nil);
    NSArray *args = alert[@"title-loc-args"];
    if (args.count == 0) {
        return title;
    }
    return [NSString stringWithFormat:title, [args tryAt:0], [args tryAt:1],[args tryAt:2], nil];
}

@end



