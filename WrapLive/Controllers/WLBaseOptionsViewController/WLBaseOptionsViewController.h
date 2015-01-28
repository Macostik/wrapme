//
//  WLBaseOptionsViewController.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditViewController.h"
#import "WLButton.h"
#import "WLContribution+Extended.h"
#import "UIView+Shorthand.h"
#import "WLAPIManager.h"
#import "WLToast.h"

static NSString *const WLDelete = @"Delete";
static NSString *const WLReport = @"Report";
static NSString *const WLLeave = @"Leave";

@interface WLBaseOptionsViewController : WLEditViewController

@property (weak, nonatomic) IBOutlet WLPressButton *deleteButton;
@property (weak, nonatomic) IBOutlet WLPressButton *downloadButton;

@property (strong, nonatomic) WLContribution *entry;

- (void)setButtonTitle;
- (void)performSelectorByTitle;
- (void)showToast;

@end
