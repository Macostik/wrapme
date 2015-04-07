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
#import "WLNotificationCell.h"

@interface WLNotificationsViewController () <WLEntryNotifyReceiver>

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLNotificationCollectionViewSection *dataSection;

@end

@implementation WLNotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.dataSection setSelection:^(WLEntry* entry) {
        if (entry.valid) {
            entry.unread = NO;
        }
        [entry present];
    }];
    
    [self.dataSection setConfigure:^(WLNotificationCell *cell, id entry) {
        [cell setBackgroundColor:[entry unread] ? [UIColor whiteColor] : [UIColor WL_grayLightest]];
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
    NSMutableOrderedSet* entries = self.dataSection.entries.entries;
    if ([entries containsObject:comment]) {
        [entries removeObject:comment];
        [self.dataSection reload];
    }
}

- (IBAction)back:(id)sender {
    [[WLEntryManager manager].context processPendingChanges];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
