//
//  WLEmailConfirmationViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmailConfirmationViewController.h"
#import "WLResendConfirmationRequest.h"
#import "WLUser+Extended.h"
#import "WLEntryNotifier.h"
#import "WLNavigation.h"
#import "UIViewController+Additions.h"

@interface WLEmailConfirmationViewController () <WLEntryNotifyReceiver>

@end

@implementation WLEmailConfirmationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[WLUser notifier] addReceiver:self];
}

- (IBAction)resend:(id)sender {
    WLResendConfirmationRequest* request = [WLResendConfirmationRequest request];
    request.email = [WLAuthorization currentAuthorization].email;
    [request send:^(id object) {
        
    } failure:^(NSError *error) {
        
    }];
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier userUpdated:(WLUser *)user {
    if (![WLAuthorization currentAuthorization].unconfirmed_email.nonempty && self.isTopViewController) {
        [self setSuccessStatusAnimated:YES];
    }
}

@end
