//
//  WLWrapOptionsViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapOptionsViewController.h"

@implementation WLWrapOptionsViewController

- (void)sendReportOrLeaveEntry {
    [self dismissViewControllerAnimated:NO completion:^{
        [self.entry leave:^(id object) {
            self.deleteButton.loading = NO;
        } failure:^(NSError *error) {
            [error show];
            self.deleteButton.loading = NO;
        }];
    }];
}

- (void)showToast {
    [WLToast showWithMessage:@"Wrap was deleted successfully."];
}

@end
