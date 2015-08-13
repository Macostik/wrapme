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

- (void)didReceiveLocalNotification:(UILocalNotification *)localNotification withCompletion:(void (^)(WKUserNotificationInterfaceType))completionHandler {
    [self.alertLabel setText:localNotification.alertBody];
    [self.titleLabel setText:localNotification.alertTitle];
    NSDictionary *userInfo = localNotification.userInfo;
    WLEntry *entry = [WLEntry entryFromDictionaryRepresentation:[userInfo dictionaryForKey:@"entry"]];
    if (entry) {
        [[WLImageCache cache] fetchIdentifiers];
        self.image.url = entry.picture.small;
    } else {
        [self.image setHidden:YES];
    }
    completionHandler(WKUserNotificationInterfaceTypeCustom);
}

@end



