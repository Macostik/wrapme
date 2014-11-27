//
//  WLLinkDeviceViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLLinkDeviceViewController.h"
#import "WLAuthorization.h"
#import "WLAuthorizationRequest.h"
#import "WLButton.h"
#import "WLProfileInformationViewController.h"
#import "WLNavigation.h"

@interface WLLinkDeviceViewController ()

@property (weak, nonatomic) IBOutlet UITextField *passcodeField;

@end

@implementation WLLinkDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[WLAuthorization currentAuthorization] signUp:^(WLAuthorization *authorization) {
    } failure:^(NSError *error) {
    }];
}

- (IBAction)next:(WLButton*)sender {
    sender.loading = YES;
    __weak typeof(self)weakSelf = self;
    WLLinkDeviceRequest *request = [WLLinkDeviceRequest request];
    request.email = [WLAuthorization currentAuthorization].email;
    request.deviceUID = [WLAuthorization currentAuthorization].deviceUID;
    request.approvalCode = self.passcodeField.text;
    [request send:^(id object) {
        [[WLAuthorization currentAuthorization] signIn:^(WLUser *user) {
            if (user.name.nonempty && user.picture.medium.nonempty) {
                [weakSelf complete];
            } else {
                [weakSelf showSuccessViewControllerAnimated:YES];
            }
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
