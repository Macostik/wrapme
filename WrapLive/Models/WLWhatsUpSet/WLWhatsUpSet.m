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
    [self update:nil failure:nil];
}

- (void)update:(WLBlock)success failure:(WLFailureBlock)failure {
    
    __weak typeof(self)weakSelf = self;
    
    NSPredicate *contributionsPredicate = [self predicateByAddingVariables:self.contributionsPredicate];
    
    NSPredicate *updatesPredicate = [self predicateByAddingVariables:self.updatesPredicate];
    
    if (updatesPredicate && contributionsPredicate) {
        [[WLEntryManager manager] performBlockInBackground:^(__autoreleasing id *result, NSError *__autoreleasing *error, NSManagedObjectContext *backgroundContext) {
            
            NSUInteger unreadEntriesCount = 0;
            
            NSMutableSet *events = [NSMutableSet set];
            NSMutableArray *contributions = [NSMutableArray array];
            [contributions adds:[backgroundContext executeFetchRequest:[WLComment fetchRequestWithPredicate:contributionsPredicate] error:error]];
            [contributions adds:[backgroundContext executeFetchRequest:[WLCandy fetchRequestWithPredicate:contributionsPredicate] error:error]];
            NSArray *updates = [backgroundContext executeFetchRequest:[WLCandy fetchRequestWithPredicate:updatesPredicate] error:error];
            
            for (WLContribution *contribution in contributions) {
                [events addObject:[WLWhatsUpEvent event:WLEventAdd contribution:contribution]];
                if (contribution.unread) {
                    unreadEntriesCount++;
                }
            }
            
            for (WLContribution *contribution in updates) {
                [events addObject:[WLWhatsUpEvent event:WLEventUpdate contribution:contribution]];
                if (contribution.unread && ![contributions containsObject:contribution]) {
                    unreadEntriesCount++;
                }
            }
            weakSelf.unreadEntriesCount = unreadEntriesCount;
            *result = events;
        } success:^(NSMutableSet *events, NSManagedObjectContext *mainContext) {
            events = [events map:^id(WLWhatsUpEvent *event) {
                WLContribution *contribution = event.contribution;
                event.contribution = [mainContext objectWithID:[contribution objectID]];
                return [contribution valid] ? event : nil;
            }];
            [weakSelf resetEntries:events];
            if (success) success();
        } failure:^(NSError *error, NSManagedObjectContext *mainContext) {
            if (failure) failure(error);
        }];
    }
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
    __weak typeof(self)weakSelf = self;
    [self update:^{
        [weakSelf.counterDelegate whatsUpSet:weakSelf figureOutUnreadEntryCounter:weakSelf.unreadEntriesCount];
    } failure:^(NSError *error) {
    }];
}

- (void)notifier:(WLEntryNotifier*)notifier didDeleteEntry:(WLEntry *)entry {
    __weak typeof(self)weakSelf = self;
    [self update:^{
        [weakSelf.counterDelegate whatsUpSet:weakSelf figureOutUnreadEntryCounter:weakSelf.unreadEntriesCount];
    } failure:^(NSError *error) {
    }];
}

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
    __weak typeof(self)weakSelf = self;
    [self update:^{
        [weakSelf.counterDelegate whatsUpSet:weakSelf figureOutUnreadEntryCounter:weakSelf.unreadEntriesCount];
    } failure:^(NSError *error) {
    }];
}

- (NSInteger)broadcasterOrderPriority:(WLBroadcaster *)broadcaster {
    return WLBroadcastReceiverOrderPriorityPrimary;
}

@end
