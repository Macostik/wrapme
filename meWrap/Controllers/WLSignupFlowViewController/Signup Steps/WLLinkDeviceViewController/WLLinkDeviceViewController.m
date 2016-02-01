//
//  WLLinkDeviceViewController.m
//  meWrap
//
//  Created by Ravenpod on 11/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLLinkDeviceViewController.h"
#import "WLProfileInformationViewController.h"

@interface WLLinkDeviceViewController ()

@property (weak, nonatomic) IBOutlet UITextField *passcodeField;

@end

@implementation WLLinkDeviceViewController

- (void)sendPasscode {
    [[[Authorization currentAuthorization] signUp] send:^(Authorization *authorization) {
    } failure:^(NSError *error) {
    }];
}

- (IBAction)next:(Button *)sender {
    sender.loading = YES;
    __weak typeof(self)weakSelf = self;
    [[APIRequest linkDevice:self.passcodeField.text] send:^(id object) {
        [[SoundPlayer player] play:Sounds01];
        [[[Authorization currentAuthorization] signIn] send:^(User *user) {
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
