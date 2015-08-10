//
//  WLLaunchScreenViewController.m
//  moji
//
//  Created by Ravenpod on 12/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLLaunchScreenViewController.h"
#import "WLLoadingView.h"

@implementation WLLaunchScreenViewController

- (void)loadView {
    self.view = [WLLoadingView splash];
}

@end
