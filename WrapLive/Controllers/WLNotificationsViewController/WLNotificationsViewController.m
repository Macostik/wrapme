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
#import "WLNotification+Extanded.h"

@interface WLNotificationsViewController () <WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet WLUserView *userView;
@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCollectionViewSection *dataSection;
@property (strong, nonatomic) WLEntryFetching *fetching;
@property (strong, nonatomic) NSMutableOrderedSet *notification;

@end

@implementation WLNotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userView.avatarView.layer.borderWidth = 1;
	self.userView.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.userView.user = [WLUser currentUser];
    self.notification = [NSMutableOrderedSet orderedSet];

    self.fetching = [WLEntryFetching fetching:@"WLEntry" configuration:^(NSFetchRequest *request) {
        [request setEntity:[WLNotification entity]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type != %@",
                                 [NSNumber numberWithInt:WLNotificationChatCandyAddition]];
        [request setPredicate:predicate];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"entry.createdAt" ascending:NO];
        [request setSortDescriptors:@[sortDescriptor]];
    }];
    __weak __typeof(self)weakSelf = self;
    [self.dataSection setConfigure:^(id cell, id entry) {
        [weakSelf.notification addObject:entry];
    }];

    [self.fetching perform];
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    run_getting_object(^id{
        return self.fetching.content;
    }, ^(NSMutableOrderedSet *notification) {
        self.dataSection.entries = notification;
    });
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.notification all:^(WLNotification *entry) {
        entry.unread = @(NO);
    }];
}

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentCreated:(WLComment*)comment {
    self.dataSection.entries = self.fetching.content;
}

@end
