//
//  WLReportCandyViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandyOptionsViewController.h"
#import "WLButton.h"
#import "UIView+QuatzCoreAnimations.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "MFMailComposeViewController+Additions.h"
#import "WLAPIManager.h"
#import "WLToast.h"

static NSString *const WLDelete = @"Delete";
static NSString *const WLReport = @"Report";

@interface WLCandyOptionsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet WLPressButton *deleteButton;
@property (weak, nonatomic) IBOutlet WLPressButton *downloadButton;

@end

@implementation WLCandyOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.deleteButton setTitle:self.candy.deletable ? WLDelete : WLReport forState:UIControlStateNormal];
    self.downloadButton.layer.borderColor = [UIColor WL_orangeColor].CGColor;
}

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

- (void)embeddingViewTapped:(UITapGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)deleteCandy:(id)sender {
    __weak __typeof(self)weakSelf = self;
    if (self.candy.deletable) {
        [self.candy remove:^(id object) {
            [WLToast showWithMessage:@"Candy was deleted successfully."];
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        } failure:^(NSError *error) {
            [error show];
        }];
    } else {
        [self dismissViewControllerAnimated:NO completion:^{
            [MFMailComposeViewController messageWithCandy:self.candy];
        }];
    }
}

- (IBAction)downloadCandy:(id)sender {
    [self.candy download:^{
    } failure:^(NSError *error) {
        [error show];
    }];
    [WLToast showPhotoDownloadingMessage];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
