//
//  WLWhatsUpSet.m
//  wrapLive
//
//  Created by Sergey Maximenko on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWhatsUpSet.h"
#import "WLWhatsUpEvent.h"

@implementation WLWhatsUpSet

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sortComparator = comparatorByDate;
        self.completed = YES;
        [[WLComment notifier] addReceiver:self];
        [[WLCandy notifier] addReceiver:self];
        [[WLWrap notifier] addReceiver:self];
    }
    return self;
}

- (void)update {
    NSMutableOrderedSet *contributions = [NSMutableOrderedSet orderedSet];
    NSDate *dayAgo = [NSDate dayAgo];
    WLUser *currentUser = [WLUser currentUser];
    [contributions unionOrderedSet:[WLComment entriesWhere:@"createdAt >= %@ AND contributor != nil AND contributor != %@", dayAgo, currentUser]];
    [contributions unionOrderedSet:[WLCandy entriesWhere:@"createdAt >= %@ AND contributor != nil AND contributor != %@", dayAgo, currentUser]];
    NSMutableOrderedSet *updates = [WLCandy entriesWhere:@"editedAt >= %@ AND editor != nil AND editor != %@", dayAgo, currentUser];
    
    NSMutableOrderedSet *events = [NSMutableOrderedSet orderedSet];
    
    for (WLContribution *contribution in contributions) {
        WLWhatsUpEvent *event = [[WLWhatsUpEvent alloc] init];
        event.event = WLEventAdd;
        event.contribution = contribution;
        [events addObject:event];
    }
    
    for (WLContribution *contribution in updates) {
        WLWhatsUpEvent *event = [[WLWhatsUpEvent alloc] init];
        event.event = WLEventUpdate;
        event.contribution = contribution;
        [events addObject:event];
    }
    
    [self resetEntries:events];
}

- (void)notifier:(WLEntryNotifier*)notifier entryAdded:(WLEntry*)entry {
    [self performSelector:@selector(update) withObject:nil afterDelay:0.0];
}

- (void)notifier:(WLEntryNotifier*)notifier entryDeleted:(WLEntry *)entry {
    [self performSelector:@selector(update) withObject:nil afterDelay:0.0];
}

- (void)notifier:(WLEntryNotifier *)notifier entryUpdated:(WLEntry *)entry {
    [self performSelector:@selector(update) withObject:nil afterDelay:0.0];
}

@end
