//
//  WLEmailConfirmationViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmailConfirmationViewController.h"
#import "WLNavigationHelper.h"
#import "WLAlertView.h"
#import "WLNotificationCenter.h"

@interface WLEmailConfirmationViewController () <WLEntryNotifyReceiver>

@property (strong, nonatomic) WLNotificationChannel* userChannel;
@property (weak, nonatomic) IBOutlet UIButton *resendEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *useAnotherEmailButton;

@end

@implementation WLEmailConfirmationViewController

- (void)dealloc {
    [self.userChannel removeObserving];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.emailLabel.text = [NSString stringWithFormat:@"%@ is not confirmed yet", [WLAuthorization currentAuthorization].email];
    
    self.useAnotherEmailButton.layer.borderWidth = 1;
    self.useAnotherEmailButton.layer.borderColor = [self.useAnotherEmailButton titleColorForState:UIControlStateNormal].CGColor;
    
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
        [WLAlertView showWithMessage:WLLS(@"sending_confirming_email")];
    } failure:^(NSError *error) {
        [error show];
    }];
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
    if (![WLAuthorization currentAuthorization].unconfirmed_email.nonempty && self.isTopViewController) {
        [WLSoundPlayer playSound:WLSound_s01];
        [self setSuccessStatusAnimated:NO];
    }
}

@end
