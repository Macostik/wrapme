//
//  WLEmailConfirmationViewController.m
//  meWrap
//
//  Created by Ravenpod on 11/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmailConfirmationViewController.h"
#import "WLNavigationHelper.h"
#import "WLAlertView.h"
#import "WLNotificationSubscription.h"
#import "WLNotification.h"
#import "WLSoundPlayer.h"

@interface WLEmailConfirmationViewController () <WLEntryNotifyReceiver, WLNotificationSubscriptionDelegate>

@property (weak, nonatomic) IBOutlet UIButton *resendEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *useAnotherEmailButton;

@end

@implementation WLEmailConfirmationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.emailLabel.text = [NSString stringWithFormat:@"%@ is not confirmed yet", [WLAuthorization currentAuthorization].email];
    self.useAnotherEmailButton.layer.borderWidth = 1;
    self.useAnotherEmailButton.layer.borderColor = [self.useAnotherEmailButton titleColorForState:UIControlStateNormal].CGColor;
    
    [[WLUser notifier] addReceiver:self];
}

- (IBAction)resend:(id)sender {
    __weak typeof(self)weakSelf = self;
    [[WLAPIRequest resendConfirmation:[WLAuthorization currentAuthorization].email] send:^(id object) {
        [UIAlertController showWithMessage:WLLS(@"sending_confirming_email")];
    } failure:^(NSError *error) {
        if ([error isError:WLErrorEmailAlreadyConfirmed]) {
            [weakSelf setSuccessStatusAnimated:NO];
            WLError(@"Your email is already confirmed.");
        } else {
            [error show];
        }
    }];
}

// MARK: - WLNotificationSubscriptionDelegate

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
    if (![WLAuthorization currentAuthorization].unconfirmed_email.nonempty && self.isTopViewController) {
        [WLSoundPlayer playSound:WLSound_s01];
        [self setSuccessStatusAnimated:NO];
    }
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return entry == [WLUser currentUser];
}

@end
