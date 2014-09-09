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
#import "WLServerTime.h"
#import "WLEntryManager.h"

@interface WLNotificationsViewController () <WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet WLUserView *userView;
@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCollectionViewSection *dataSection;
@property (strong, nonatomic) NSMutableOrderedSet *notification;

@end

static CGFloat WLCountOfDays = 7;

@implementation WLNotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userView.avatarView.layer.borderWidth = 1;
	self.userView.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.userView.user = [WLUser currentUser];
    self.notification = [NSMutableOrderedSet orderedSet];
    
    __weak __typeof(self)weakSelf = self;
    [self.dataSection setConfigure:^(id cell, id entry) {
        [weakSelf.notification addObject:entry];
    }];
 
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self displayNotificatioByCriteria];
}

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentCreated:(WLComment*)comment {
    [self displayNotificatioByCriteria];
}

- (void)displayNotificatioByCriteria {
    NSMutableOrderedSet *buffer = [NSMutableOrderedSet orderedSet];
    NSDate *endDate = [[WLServerTime current] dayByAddingDayCount:-WLCountOfDays];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdAt >= %@ AND contributor != %@", endDate, [WLUser currentUser]];
    [[WLComment entriesWithPredicate:predicate sorterByKey:@"createdAt"] all:^(WLComment *comment) {
        if ([[comment candy].contributor isCurrentUser]) {
            [buffer addObject:comment];
        } else {
            BOOL flag = NO;
            for (WLComment* _comment in comment.candy.comments) {
                if ([_comment.contributor isCurrentUser]) {
                    flag = YES;
                } else if (flag && _comment == comment) {
                    [buffer addObject:comment];
                    break;
                }
            }
        }
    }];
    self.dataSection.entries = buffer;
}

- (IBAction)back:(id)sender {
    [self.notification all:^(WLComment *commment) {
        commment.unread = @(NO);
    }];
    [[WLEntryManager manager] save];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
