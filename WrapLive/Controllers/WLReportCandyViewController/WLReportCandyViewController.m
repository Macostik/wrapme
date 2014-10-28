//
//  WLReportCandyViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLReportCandyViewController.h"
#import "WLButton.h"

@interface WLReportCandyViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet WLPressButton *deleteButton;
@property (weak, nonatomic) IBOutlet WLPressButton *cancelButton;

@end

@implementation WLReportCandyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.contentView.layer.cornerRadius = 6.0f;
}

@end
