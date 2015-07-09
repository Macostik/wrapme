//
//  WLWhatsUpSet.m
//  wrapLive
//
//  Created by Sergey Maximenko on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWhatsUpSet.h"
#import "WLWhatsUpEvent.h"

@interface WLWhatsUpSet () <WLEntryNotifyReceiver>

@property (strong, nonatomic) NSPredicate* contributionsPredicate;

@property (strong, nonatomic) NSPredicate* updatesPredicate;

@end

@implementation WLWhatsUpSet

+ (instancetype)sharedSet {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sortComparator = comparatorByDate;
        self.completed = YES;
        [[WLComment notifier] addReceiver:self];
        [[WLCandy notifier] addReceiver:self];
        [[WLWrap notifier] addReceiver:self];
        self.contributionsPredicate = [NSPredicate predicateWithFormat:@"createdAt >= $DATE AND contributor != nil AND contributor != $CURRENT_USER"];
        self.updatesPredicate = [NSPredicate predicateWithFormat:@"editedAt >= $DATE AND editor != nil AND editor != $CURRENT_USER"];
        [self update];
    }
    return self;
}

- (NSPredicate *)predicateByAddingVariables:(NSPredicate*)predicate {
    NSDate *dayAgo = [NSDate dayAgo];
    WLUser *currentUser = [WLUser currentUser];
    if (dayAgo && currentUser) {
        NSDictionary *variables = @{@"DATE":dayAgo, @"CURRENT_USER":currentUser};
        return [predicate predicateWithSubstitutionVariables:variables];
    }
    return nil;
}

- (void)update {
    
    NSUInteger unreadEntriesCount = 0;
    
    NSMutableSet *events = [NSMutableSet set];
    
    NSPredicate *contributionsPredicate = [self predicateByAddingVariables:self.contributionsPredicate];
    
    NSPredicate *updatesPredicate = [self predicateByAddingVariables:self.updatesPredicate];
    
    if (updatesPredicate && contributionsPredicate) {
        NSMutableOrderedSet *contributions = [NSMutableOrderedSet orderedSet];
        [contributions unionOrderedSet:[WLComment entriesWithPredicate:contributionsPredicate]];
        [contributions unionOrderedSet:[WLCandy entriesWithPredicate:contributionsPredicate]];
        NSMutableOrderedSet *updates = [WLCandy entriesWithPredicate:updatesPredicate];
        
        for (WLContribution *contribution in contributions) {
            WLWhatsUpEvent *event = [[WLWhatsUpEvent alloc] init];
            event.event = WLEventAdd;
            event.contribution = contribution;
            [events addObject:event];
            if (contribution.unread) {
                unreadEntriesCount++;
            }
        }
        
        for (WLContribution *contribution in updates) {
            WLWhatsUpEvent *event = [[WLWhatsUpEvent alloc] init];
            event.event = WLEventUpdate;
            event.contribution = contribution;
            [events addObject:event];
            if (contribution.unread && ![contributions containsObject:contribution]) {
                unreadEntriesCount++;
            }
        }
    }
    
    self.unreadEntriesCount = unreadEntriesCount;
    [self resetEntries:events];
}

- (NSUInteger)unreadCandiesCountForWrap:(WLWrap *)wrap {
    NSMutableSet *unreadCandies = [NSMutableSet set];
    for (WLWhatsUpEvent *event in self.entries) {
        WLCandy *candy = event.contribution;
        if ([candy isKindOfClass:[WLCandy class]] && candy.wrap == wrap && [candy unread]) {
            [unreadCandies addObject:candy];
        }
    }
    return unreadCandies.count;
}

- (void)notifier:(WLEntryNotifier*)notifier didAddEntry:(WLEntry*)entry {
    [self update];
    [self.counterDelegate whatsUpSet:self figureOutUnreadEntryCounter:self.unreadEntriesCount];
}

- (void)notifier:(WLEntryNotifier*)notifier didDeleteEntry:(WLEntry *)entry {
    [self update];
    [self.counterDelegate whatsUpSet:self figureOutUnreadEntryCounter:self.unreadEntriesCount];
}

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
    [self update];
    [self.counterDelegate whatsUpSet:self figureOutUnreadEntryCounter:self.unreadEntriesCount];
}

- (NSInteger)broadcasterOrderPriority:(WLBroadcaster *)broadcaster {
    return WLBroadcastReceiverOrderPriorityPrimary;
}

@end
