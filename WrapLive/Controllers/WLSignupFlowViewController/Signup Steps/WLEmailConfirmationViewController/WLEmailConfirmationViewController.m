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
        self.userChannel = [WLNotificationChannel channelWithName:userUID];
        [self.userChannel observeMessages:^(PNMessage *message) {
            WLEntryNotification *notification = [WLEntryNotification notificationWithMessage:message];
            if (notification.type == WLNotificationUserUpdate) {
                [notification createTargetEntry];
                if (![WLAuthorization currentAuthorization].unconfirmed_email.nonempty && self.isTopViewController) {
                    [WLSoundPlayer playSound:WLSound_s01];
                    [self setSuccessStatusAnimated:NO];
                }
            }
        }];
    }
}

- (IBAction)resend:(id)sender {
    __weak typeof(self)weakSelf = self;
    WLResendConfirmationRequest* request = [WLResendConfirmationRequest request];
    request.email = [WLAuthorization currentAuthorization].email;
    [request send:^(id object) {
        [WLAlertView showWithMessage:WLLS(@"sending_confirming_email")];
    } failure:^(NSError *error) {
        if ([error isError:WLErrorEmailAlreadyConfirmed]) {
            [weakSelf setSuccessStatusAnimated:NO];
            WLError(@"Your email is already confirmed.");
        } else {
            [error show];
        }
    }];
}

@end
