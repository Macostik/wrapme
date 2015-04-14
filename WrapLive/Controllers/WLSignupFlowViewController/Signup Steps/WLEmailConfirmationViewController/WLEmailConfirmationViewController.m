//
//  WLEmailConfirmationViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmailConfirmationViewController.h"
#import "WLNavigationHelper.h"
#import "WLNotificationChannel.h"
#import "WLSoundPlayer.h"
#import "UIAlertView+Blocks.h"
#import "WLNotification+PNMessage.h"

@interface WLEmailConfirmationViewController () <WLEntryNotifyReceiver>

@property (strong, nonatomic) WLNotificationChannel* userChannel;

@end

@implementation WLEmailConfirmationViewController

- (void)dealloc {
    [self.userChannel removeObserving];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *userUID = [WLUser currentUser].identifier;
    if (userUID.nonempty) {
        [[WLUser notifier] addReceiver:self];
        self.userChannel = [WLNotificationChannel channelWithName:userUID];
        [self.userChannel observeMessages:^(PNMessage *message) {
            WLNotification *notification = [WLNotification notificationWithMessage:message];
            if (notification.type == WLNotificationUserUpdate) {
                [notification fetch:nil failure:nil];
            }
        }];
    }
}

- (IBAction)resend:(id)sender {
    WLResendConfirmationRequest* request = [WLResendConfirmationRequest request];
    request.email = [WLAuthorization currentAuthorization].email;
    [request send:^(id object) {
        [UIAlertView showWithMessage:WLLS(@"We are sending you an email for confirming your email address now.")];
    } failure:^(NSError *error) {
        
    }];
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier userUpdated:(WLUser *)user {
    if (![WLAuthorization currentAuthorization].unconfirmed_email.nonempty && self.isTopViewController) {
        [WLSoundPlayer playSound:WLSound_s01];
        [self setSuccessStatusAnimated:YES];
    }
}

@end
