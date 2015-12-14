//
//  WLEmailConfirmationViewController.m
//  meWrap
//
//  Created by Ravenpod on 11/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmailConfirmationViewController.h"
#import "WLSoundPlayer.h"

@interface WLEmailConfirmationViewController () <EntryNotifying, NotificationSubscriptionDelegate>

@property (weak, nonatomic) IBOutlet UIButton *resendEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *useAnotherEmailButton;

@end

@implementation WLEmailConfirmationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.emailLabel.text = [NSString stringWithFormat:@"%@ is not confirmed yet", [Authorization currentAuthorization].email];
    self.useAnotherEmailButton.layer.borderWidth = 1;
    self.useAnotherEmailButton.layer.borderColor = [self.useAnotherEmailButton titleColorForState:UIControlStateNormal].CGColor;
    
    [[User notifier] addReceiver:self];
}

- (IBAction)resend:(id)sender {
    __weak typeof(self)weakSelf = self;
    [[WLAPIRequest resendConfirmation:[Authorization currentAuthorization].email] send:^(id object) {
        [[UIAlertController alert:@"sending_confirming_email".ls] show];
    } failure:^(NSError *error) {
        if ([error isResponseError:ResponseCodeEmailAlreadyConfirmed]) {
            [weakSelf setSuccessStatusAnimated:NO];
            [[[NSError alloc] initWithMessage:@"Your email is already confirmed."] show];
        } else {
            [error show];
        }
    }];
}

// MARK: - NotificationSubscriptionDelegate

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Entry *)entry event:(enum EntryUpdateEvent)event {
    if (![Authorization currentAuthorization].unconfirmed_email.nonempty && self.isTopViewController) {
        [WLSoundPlayer playSound:WLSound_s01];
        [self setSuccessStatusAnimated:NO];
    }
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return entry == [User currentUser];
}

@end
