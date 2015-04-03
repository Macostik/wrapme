//
//  WLNotificationsViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationsViewController.h"
#import "WLUserView.h"
#import "WLCollectionViewDataProvider.h"
#import "WLNotificationCenter.h"
#import "WLNavigation.h"
#import "WLNotificationCollectionViewSection.h"

@interface WLNotificationsViewController () <WLEntryNotifyReceiver>

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLNotificationCollectionViewSection *dataSection;
@property (strong, nonatomic) NSMutableOrderedSet *readNotifications;

@end

@implementation WLNotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.readNotifications = [NSMutableOrderedSet orderedSet];
    
    __weak __typeof(self)weakSelf = self;
    [self.dataSection setConfigure:^(id cell, id entry) {
        [weakSelf.readNotifications addObject:entry];
    }];
    
    [self.dataSection setSelection:^(WLEntry* entry) {
        [entry present];
    }];
 
    [[WLComment notifier] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.dataSection.entries = [[WLUser currentUser] notifications];
}

- (void)notifier:(WLEntryNotifier*)notifier commentAdded:(WLComment*)comment {
    self.dataSection.entries = [[WLUser currentUser] notifications];
}

- (void)notifier:(WLEntryNotifier*)notifier commentDeleted:(WLComment *)comment {
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
                commment.unread = NO;
            }
        }];
    }
    [[WLEntryManager manager].context processPendingChanges];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
