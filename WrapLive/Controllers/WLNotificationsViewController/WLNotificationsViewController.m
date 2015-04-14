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
#import "WLChronologicalEntryPresenter.h"
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
        [WLChronologicalEntryPresenter presentEntry:entry animated:YES];
    }];
    
    [self.dataSection setConfigure:^(WLNotificationCell *cell, id entry) {
        [cell setBackgroundColor:[entry unread]  ? [UIColor whiteColor] : [UIColor WL_grayLightest]];
    }];
 
    [[WLComment notifier] addReceiver:self];
    [[WLCandy notifier] addReceiver:self];
    [[WLMessage notifier] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.dataSection.entries = [[WLUser currentUser] notifications];
}

- (void)updateNotificaton {
    if (![WLKeyboard keyboard].isShow) {
       self.dataSection.entries = [[WLUser currentUser] notifications];
    }
}

- (void)removeNotificationEntry:(WLEntry *)entry {
    NSMutableOrderedSet* entries = self.dataSection.entries.entries;
    if ([entries containsObject:entry]) {
        [entries removeObject:entry];
        if (![WLKeyboard keyboard].isShow) {
             [self.dataSection reload];
        }
    }
}

- (void)notifier:(WLEntryNotifier*)notifier commentAdded:(WLComment*)comment {
    [self updateNotificaton];
}

- (void)notifier:(WLEntryNotifier *)notifier candyAdded:(WLCandy *)candy {
    [self updateNotificaton];
}

- (void)notifier:(WLEntryNotifier *)notifier messageAdded:(WLMessage *)message {
    [self updateNotificaton];
}

- (void)notifier:(WLEntryNotifier*)notifier commentDeleted:(WLComment *)comment {
    [self removeNotificationEntry:comment];
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    [self removeNotificationEntry:candy];
}

- (void)notifier:(WLEntryNotifier *)notifier messageDeleted:(WLMessage *)message {
    [self removeNotificationEntry:message];
}

- (IBAction)back:(id)sender {
    [[WLEntryManager manager].context processPendingChanges];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)keyboardDidHide:(WLKeyboard*)keyboard {
    self.dataSection.entries = [[WLUser currentUser] notifications];
}

@end
