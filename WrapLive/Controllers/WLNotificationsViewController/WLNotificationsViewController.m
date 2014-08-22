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
#import "WLCollectionViewDataProvider.h"
#import "WLCollectionViewSection.h"
#import "WLNotificationCenter.h"

@interface WLNotificationsViewController () <WLNotificationReceiver>

@property (weak, nonatomic) IBOutlet WLUserView *userView;
@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCollectionViewSection *dataSection;

@end

@implementation WLNotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.userView.avatarView.layer.borderWidth = 1;
	self.userView.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.userView.user = [WLUser currentUser];
    
    __weak typeof(self)weakSelf = self;
    run_getting_object(^id{
        return [WLNotificationCenter defaultCenter].storedNotifications;
    }, ^(NSMutableOrderedSet* notifications) {
        weakSelf.dataSection.entries = notifications;
    });
    
    [[WLNotificationCenter defaultCenter] addReceiver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [WLNotificationCenter defaultCenter].unreadNotificationsCount = 0;
}

#pragma mark - WLNotificationReceiver

- (void)broadcaster:(WLNotificationCenter *)broadcaster didStoreNotification:(WLNotification *)notification {
    self.dataSection.entries = [WLNotificationCenter defaultCenter].storedNotifications;
}

@end
