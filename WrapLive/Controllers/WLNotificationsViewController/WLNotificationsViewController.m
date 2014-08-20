//
//  WLNotificationsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationsViewController.h"
#import "WLUserView.h"
#import "WLUser+Extended.h"
#import "WLImageFetcher.h"

@interface WLNotificationsViewController ()

@property (weak, nonatomic) IBOutlet WLUserView *userView;

@end

@implementation WLNotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.userView.avatarView.layer.borderWidth = 1;
	self.userView.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.userView.user = [WLUser currentUser];
}

@end
