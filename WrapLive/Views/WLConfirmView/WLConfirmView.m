//
//  WLConfirmView.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLConfirmView.h"

@interface WLConfirmView ()

@property (strong, nonatomic) WLBlock success;
@property (strong, nonatomic) WLBlock failure;

@end

@implementation WLConfirmView

- (void)confirmationSuccess:(WLBlock)succes failure:(WLBlock)failure {
    self.success = succes;
    self.failure = failure;
}

- (IBAction)buttonClick:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"OK"]) {
        self.success();
    } else {
        self.failure();
    }
    [self removeFromSuperview];
}

@end
