//
//  WLLinkDeviceViewController.m
//  moji
//
//  Created by Ravenpod on 11/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLLinkDeviceViewController.h"
#import "WLButton.h"
#import "WLProfileInformationViewController.h"
#import "WLNavigationHelper.h"
#import "WLSoundPlayer.h"

@interface WLLinkDeviceViewController ()

@property (weak, nonatomic) IBOutlet UITextField *passcodeField;

@end

@implementation WLLinkDeviceViewController

- (void)sendPasscode {
    [[WLAuthorization currentAuthorization] signUp:^(WLAuthorization *authorization) {
    } failure:^(NSError *error) {
    }];
}

- (IBAction)next:(WLButton*)sender {
    sender.loading = YES;
    __weak typeof(self)weakSelf = self;
    [[WLAuthorizationRequest linkDevice:self.passcodeField.text] send:^(id object) {
        [WLSoundPlayer playSound:WLSound_s01];
        [[WLAuthorization currentAuthorization] signIn:^(WLUser *user) {
            [weakSelf setSuccessStatusAnimated:NO];
        } failure:^(NSError *error) {
            [error show];
            sender.loading = NO;
        }];
    } failure:^(NSError *error) {
        [error show];
        sender.loading = NO;
    }];
}

@end
