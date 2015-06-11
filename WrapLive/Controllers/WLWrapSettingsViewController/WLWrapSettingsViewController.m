//
//  WLWrapSettingsViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/06/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapSettingsViewController.h"
#import "WLButton.h"
#import "WLToast.h"

@interface WLWrapSettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *wrapName;
@property (weak, nonatomic) IBOutlet WLButton *actionButton;
@property (weak, nonatomic) IBOutlet UISwitch *photoNotifyTrigger;
@property (weak, nonatomic) IBOutlet UISwitch *chatNotifyTrigger;

@end

@implementation WLWrapSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.wrapName.text = self.wrap.name;
    [self.actionButton setTitle:self.wrap.deletable ? WLLS(@"delete_wrap") : WLLS(@"leave_wrap")  forState:UIControlStateNormal];
}

- (IBAction)handleAction:(WLButton *)sender {
    __weak __typeof(self)weakSelf = self;
    sender.loading = YES;
    if (self.wrap.deletable) {
        [self.wrap remove:^(id object) {
            if (object != nil) {
                [WLToast showWithMessage:WLLS(@"delete_wrap_success")];
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
            }
            sender.loading = NO;
        } failure:^(NSError *error) {
            if ([error isError:WLErrorActionCancelled]) {
                [weakSelf.navigationController popViewControllerAnimated:NO];
                sender.loading = NO;
            } else {
                [error show];
                sender.loading = NO;
            }
        }];
    } else {
        [self.wrap leave:^(id object) {
            if (object != nil) {
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
            }
            sender.loading = NO;
        } failure:^(NSError *error) {
            if ([error isError:WLErrorActionCancelled]) {
                [weakSelf.navigationController popViewControllerAnimated:NO];
                sender.loading = NO;
            } else {
                [error show];
                sender.loading = NO;
            }
        }];
    }
}

@end
