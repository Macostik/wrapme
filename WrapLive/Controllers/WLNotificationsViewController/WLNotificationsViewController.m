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
#import "WLNotification.h"
#import "WLEntryFetching.h"
#import "WLWrapBroadcaster.h"
#import "NSDate+Formatting.h"
#import "WLEntryManager.h"
#import "WLNavigation.h"
#import "WLNotificationCollectionViewSection.h"

@interface WLNotificationsViewController () <WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet WLUserView *userView;
@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLNotificationCollectionViewSection *dataSection;
@property (strong, nonatomic) NSMutableOrderedSet *readNotifications;

@end

@implementation WLNotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userView.avatarView.layer.borderWidth = 1;
	self.userView.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.userView.user = [WLUser currentUser];
    self.readNotifications = [NSMutableOrderedSet orderedSet];
    
    __weak __typeof(self)weakSelf = self;
    [self.dataSection setConfigure:^(id cell, id entry) {
        [weakSelf.readNotifications addObject:entry];
    }];
    
    [self.dataSection setSelection:^(WLEntry* entry) {
        [entry present];
    }];
 
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.dataSection.entries = [[WLUser currentUser] notifications];
}

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentCreated:(WLComment*)comment {
    self.dataSection.entries = [[WLUser currentUser] notifications];
}

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentRemoved:(WLComment *)comment {
    if ([self.readNotifications containsObject:comment]) {
        [self.readNotifications removeObject:comment];
    }
    NSMutableOrderedSet* entries = self.dataSection.entries.entries;
    if ([entries containsObject:comment]) {
        [entries removeObject:comment];
        [self.dataSection reload];
    }
}

- (IBAction)back:(id)sender {
    if (self.readNotifications.nonempty) {
        [self.readNotifications all:^(WLComment *commment) {
            if (commment.valid) {
                commment.unread = @(NO);
            }
        }];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
