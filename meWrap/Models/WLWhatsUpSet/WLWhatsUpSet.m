//
//  WLWhatsUpSet.m
//  meWrap
//
//  Created by Ravenpod on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWhatsUpSet.h"
#import "WLWhatsUpEvent.h"

@interface WLWhatsUpSet () <WLEntryNotifyReceiver>

@property (strong, nonatomic) NSString* contributionsPredicate;

@property (strong, nonatomic) NSString* updatesPredicate;

@property (strong, nonatomic) NSDictionary *wrapCounters;

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
        self.broadcaster = [[WLBroadcaster alloc] init];
        self.wrapCounters = [NSDictionary dictionary];
        self.sortComparator = comparatorByDate;
        [[WLComment notifier] addReceiver:self];
        [[WLCandy notifier] addReceiver:self];
        [[WLWrap notifier] addReceiver:self];
        self.contributionsPredicate = @"createdAt >= %@ AND contributor != nil AND contributor != %@";
        self.updatesPredicate = @"editedAt >= %@ AND editor != nil AND editor != %@";
        [self update:nil failure:nil];
    }
    return self;
}

- (NSString *)predicateByAddingVariables:(NSString*)predicate {
    NSDate *dayAgo = [NSDate dayAgo];
    WLUser *currentUser = [WLUser currentUser];
    if (dayAgo && currentUser) {
        return [NSString stringWithFormat:predicate, dayAgo, currentUser];
    }
    return nil;
}

- (void)update:(WLBlock)success failure:(WLFailureBlock)failure {
    
    __weak typeof(self)weakSelf = self;
    NSDate *dayAgo = [NSDate dayAgo];
    WLUser *currentUser = [WLUser currentUser];
    if (dayAgo && currentUser) {
        [[WLEntryManager manager] performBlockInBackground:^(__autoreleasing id *result, NSError *__autoreleasing *error, NSManagedObjectContext *backgroundContext) {
            
            NSUInteger unreadEntriesCount = 0;
            
            NSMutableDictionary *wrapCounters = [NSMutableDictionary dictionary];
            
            NSMutableSet *events = [NSMutableSet set];
            NSMutableArray *contributions = [NSMutableArray array];
            [contributions adds:[[WLComment fetchRequest:weakSelf.contributionsPredicate, dayAgo, currentUser] executeInContext:backgroundContext]];
            [contributions adds:[[WLCandy fetchRequest:weakSelf.contributionsPredicate, dayAgo, currentUser] executeInContext:backgroundContext]];
            NSArray *updates = [[WLCandy fetchRequest:weakSelf.updatesPredicate, dayAgo, currentUser] executeInContext:backgroundContext];
            
            for (WLContribution *contribution in contributions) {
                [events addObject:[WLWhatsUpEvent event:WLEventAdd contribution:contribution]];
                if (contribution.unread) {
                    unreadEntriesCount++;
                    if ([contribution isKindOfClass:[WLCandy class]]) {
                        NSString *wrapId = [[(WLCandy*)contribution wrap] identifier];
                        if (wrapId) {
                            wrapCounters[wrapId] = @([wrapCounters[wrapId] unsignedIntegerValue] + 1);
                        }
                    }
                }
            }
            
            for (WLContribution *contribution in updates) {
                [events addObject:[WLWhatsUpEvent event:WLEventUpdate contribution:contribution]];
                if (contribution.unread) {
                    unreadEntriesCount++;
                }
            }
            weakSelf.unreadEntriesCount = unreadEntriesCount;
            weakSelf.wrapCounters = [wrapCounters copy];
            *result = events;
        } success:^(NSMutableSet *events, NSManagedObjectContext *mainContext) {
            events = [events map:^id(WLWhatsUpEvent *event) {
                WLContribution *contribution = event.contribution;
                NSError *error = nil;
                NSManagedObject *existingContributor = [mainContext existingObjectWithID:[contribution objectID] error:&error];
                if (existingContributor != nil && !existingContributor.fault) {
                    event.contribution = existingContributor;
                }
                return [event.contribution valid] && !error ? event : nil;
            }];
            [weakSelf resetEntries:events];
            if (success) success();
        } failure:^(NSError *error, NSManagedObjectContext *mainContext) {
            if (failure) failure(error);
        }];
    }
}

- (void)refreshCount:(void (^)(NSUInteger))success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self update:^{
        if (success) success(weakSelf.unreadEntriesCount);
    } failure:failure];
}

- (NSUInteger)unreadCandiesCountForWrap:(WLWrap *)wrap {
    return [self.wrapCounters[wrap.identifier] unsignedIntegerValue];
}

- (void)notifier:(WLEntryNotifier*)notifier didAddEntry:(WLEntry*)entry {
    if ([[(WLContribution*)entry contributor] current]) {
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self update:^{
        [weakSelf.broadcaster broadcast:@selector(whatsUpBroadcaster:updated:) object:weakSelf];
    } failure:^(NSError *error) {
    }];
}

- (void)notifier:(WLEntryNotifier*)notifier didDeleteEntry:(WLEntry *)entry {
    if ([[(WLContribution*)entry contributor] current]) {
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self update:^{
        [weakSelf.broadcaster broadcast:@selector(whatsUpBroadcaster:updated:) object:weakSelf];
    } failure:^(NSError *error) {
    }];
}

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
    __weak typeof(self)weakSelf = self;
    [self update:^{
        [weakSelf.broadcaster broadcast:@selector(whatsUpBroadcaster:updated:) object:weakSelf];
    } failure:^(NSError *error) {
    }];
}

- (NSInteger)broadcasterOrderPriority:(WLBroadcaster *)broadcaster {
    return WLBroadcastReceiverOrderPriorityPrimary;
}

@end
