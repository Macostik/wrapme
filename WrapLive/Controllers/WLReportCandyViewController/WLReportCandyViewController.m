//
//  WLReportCandyViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLReportCandyViewController.h"
#import "WLButton.h"
#import "UIView+QuatzCoreAnimations.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "MFMailComposeViewController+Additions.h"
#import "WLAPIManager.h"
#import "WLToast.h"

static NSString *const WLDelete = @"Delete";
static NSString *const WLReport = @"Report";

@interface WLReportCandyViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet WLPressButton *deleteButton;
@property (weak, nonatomic) IBOutlet WLPressButton *cancelButton;

@end

@implementation WLReportCandyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleLabel.text = [NSString stringWithFormat:@"%@ this candy", [self isMyCandy] ? WLDelete : WLReport];
    [self.deleteButton setTitle:[self isMyCandy] ? WLDelete : WLReport forState:UIControlStateNormal];
    self.cancelButton.layer.borderColor = self.deleteButton.layer.borderColor = [UIColor WL_orangeColor].CGColor;

    [self.contentView bottomPushWithDuration:1.0 delegate:nil];
}

- (BOOL)isMyCandy {
    return [self.candy.contributor isCurrentUser] || [self.candy.wrap.contributor isCurrentUser];
}

- (IBAction)removeFromController:(id)sender {
    UIViewController *parentViewController = [self parentViewController];
    [UIView animateWithDuration:1.0f animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(.0f, self.parentViewController.view.height);
    } completion:^(BOOL finished) {
        [parentViewController.view removeFromSuperview];
        [parentViewController removeFromParentViewController];
    }];
}

- (IBAction)deleteCandy:(id)sender {
    __weak __typeof(self)weakSelf = self;
    if ([self isMyCandy]) {
        [self.candy remove:^(id object) {
            [WLToast showWithMessage:@"Candy was deleted successfully."];
            [weakSelf removeFromController:nil];
        } failure:^(NSError *error) {
            [error show];
        }];
    } else {
        [MFMailComposeViewController messageWithCandy:self.candy];
    }
}

@end
