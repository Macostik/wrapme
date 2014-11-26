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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)resend:(id)sender {
    
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier userUpdated:(WLUser *)user {
    if (![WLAuthorization currentAuthorization].unconfirmed_email.nonempty && self.isOnTopOfNagvigation) {
        [self.navigationController pushViewController:[WLAuthorizationSceneViewController instantiateWithIdentifier:@"WLEmailConfirmationSuccessViewController" storyboard:self.storyboard] animated:YES];
    }
}

@end
