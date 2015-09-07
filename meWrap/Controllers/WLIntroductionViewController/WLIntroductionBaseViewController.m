//
//  WLIntroductionBaseViewController.m
//  meWrap
//
//  Created by Ravenpod on 3/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIntroductionBaseViewController.h"

@interface WLIntroductionBaseViewController ()

@end

@implementation WLIntroductionBaseViewController

- (IBAction)continueIntroduction:(id)sender {
    [self.delegate introductionBaseViewControllerDidContinueIntroduction:self];
}

- (IBAction)finishIntroduction:(id)sender {
    [self.delegate introductionBaseViewControllerDidFinishIntroduction:self];
}

@end
