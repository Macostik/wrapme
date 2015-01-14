//
//  WLReportCandyViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandyOptionsViewController.h"
#import "UIView+QuatzCoreAnimations.h"
#import "UIColor+CustomColors.h"
#import "MFMailComposeViewController+Additions.h"

@implementation WLCandyOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.deleteButton setTitle:self.entry.deletable ? WLLS(WLDelete) : WLLS(WLReport) forState:UIControlStateNormal];
    self.downloadButton.layer.borderColor = [UIColor WL_orangeColor].CGColor;
}

- (IBAction)downloadCandy:(id)sender {
    [self.entry download:^{
    } failure:^(NSError *error) {
        [error show];
    }];
    [WLToast showPhotoDownloadingMessage];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendReportOrLeaveEntry {
    [self dismissViewControllerAnimated:NO completion:^{
        [MFMailComposeViewController messageWithCandy:self.entry];
    }];
}

- (void)showToast {
    [WLToast showWithMessage:WLLS(@"Candy was deleted successfully.")];
}

@end
