//
//  WLIntroductionStepViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIntroductionStepViewController.h"

@interface WLIntroductionStepViewController ()

@end

@implementation WLIntroductionStepViewController

- (IBAction)continueIntroduction:(id)sender {
    [self.delegate introductionStepViewControllerDidContinue:self];
}

- (IBAction)finishIntroduction:(id)sender {
    [self.delegate introductionStepViewControllerDidFinish:self];
}

@end
