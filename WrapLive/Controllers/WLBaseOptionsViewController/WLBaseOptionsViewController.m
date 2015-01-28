//
//  WLBaseOptionsViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseOptionsViewController.h"

@implementation WLBaseOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setButtonTitle];
}

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

- (void)embeddingViewTapped:(UITapGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)deleteEntry:(WLButton *)sender {
    __weak __typeof(self)weakSelf = self;
    if (self.entry.deletable) {
        sender.loading = YES;
        [self.entry remove:^(id object) {
            [weakSelf showToast];
            sender.loading = NO;
            [weakSelf dismissViewControllerAnimated:NO completion:nil];
        } failure:^(NSError *error) {
            [error show];
            sender.loading = NO;
        }];
    } else {
        [self performSelectorByTitle];
    }
}

- (void)setButtonTitle {}

- (void)performSelectorByTitle {}

- (void)showToast {}

@end
