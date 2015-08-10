//
//  WLEmailViewController.m
//  moji
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmailViewController.h"
#import "WLTelephony.h"
#import "WLButton.h"
#import "WLTestUserPicker.h"
#import "WLNavigationHelper.h"
#import "NSObject+NibAdditions.h"
#import "WLConfirmView.h"

@interface WLEmailViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UIButton *testAccountButton;

@end

@implementation WLEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.emailField.text = [WLAuthorization currentAuthorization].email;
}

- (IBAction)next:(WLButton*)sender {
    sender.loading = YES;
    [self.view endEditing:YES];
    __weak typeof(self)weakSelf = self;
    [[WLAuthorizationRequest whois:self.emailField.text] send:^(WLWhoIs* whoIs) {
        sender.loading = NO;
        if (whoIs.found && whoIs.requiresApproving) {
            if (whoIs.confirmed) {
                [weakSelf setStatus:WLEmailStepStatusLinkDevice animated:NO];
            } else {
                [weakSelf setStatus:WLEmailStepStatusUnconfirmedEmail animated:NO];
            }
        } else {
            [weakSelf setStatus:WLEmailStepStatusVerification animated:NO];
        }
    } failure:^(NSError *error) {
        sender.loading = NO;
        [error show];
    }];
}

- (IBAction)useTestAccount:(id)sender {
    __weak typeof(self)weakSelf = self;
    [WLTestUserPicker showInView:self.view.window selection:^(WLAuthorization *authorization) {
        [WLConfirmView showInView:weakSelf.view authorization:authorization success:^(WLAuthorization *authorization) {
            if (authorization.password.nonempty) {
                [authorization signIn:^(WLUser *user) {
                    [[UIStoryboard storyboardNamed:WLMainStoryboard] present:NO];
                } failure:^(NSError *error) {
                    [error show];
                }];
            }
        } cancel:nil];
    }];
}

@end
