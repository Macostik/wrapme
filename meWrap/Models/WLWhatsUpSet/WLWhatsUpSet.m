//
//  WLWhatsUpSet.m
//  meWrap
//
//  Created by Ravenpod on 5/25/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWhatsUpSet.h"

@interface WLWhatsUpSet () <EntryNotifying>

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
        [[Comment notifier] addReceiver:self];
        [[Candy notifier] addReceiver:self];
        [[Wrap notifier] addReceiver:self];
        self.contributionsPredicate = @"createdAt >= %@ AND contributor != nil AND contributor != %@";
        self.updatesPredicate = @"editedAt >= %@ AND editor != nil AND editor != %@";
        [self update:nil failure:nil];
    }
    return self;
}

- (NSString *)predicateByAddingVariables:(NSString*)predicate {
    NSDate *dayAgo = [NSDate dayAgo];
    User *currentUser = [User currentUser];
    if (dayAgo && currentUser) {
        return [NSString stringWithFormat:predicate, dayAgo, currentUser];
    }
    return nil;
}

- (void)update:(WLBlock)success failure:(WLFailureBlock)failure {
    
    __weak typeof(self)weakSelf = self;
    NSDate *dayAgo = [NSDate dayAgo];
    User *currentUser = [User currentUser];
    if (dayAgo && currentUser) {
        NSMutableArray *contributions = [NSMutableArray array];
        
        NSFetchRequest *request = [Comment fetch];
        request.predicate = [NSPredicate predicateWithFormat:weakSelf.contributionsPredicate, dayAgo, currentUser];
        [request execute:^(NSArray *result) {
            [contributions adds:result];
            NSFetchRequest *request = [Candy fetch];
            request.predicate = [NSPredicate predicateWithFormat:weakSelf.contributionsPredicate, dayAgo, currentUser];
            [request execute:^(NSArray *result) {
                [contributions adds:result];
                NSFetchRequest *request = [Candy fetch];
                request.predicate = [NSPredicate predicateWithFormat:weakSelf.updatesPredicate, dayAgo, currentUser];
                [request execute:^(NSArray *result) {
                    NSArray *updates = result;
                    [weakSelf handleControbutions:contributions updates:updates];
                    if (success) success();
                }];
            }];
        }];
    } else if (failure) {
        failure(nil);
    }
}

- (void)handleControbutions:(NSArray*)contributions updates:(NSArray*)updates {
    NSMutableDictionary *wrapCounters = [NSMutableDictionary dictionary];
    NSUInteger unreadEntriesCount = 0;
    NSMutableSet *events = [NSMutableSet set];
    for (Contribution *contribution in contributions) {
        if (contribution.valid) {
            [events addObject:[[WhatsUpEvent alloc] initWithEvent:WLEventAdd contribution:contribution]];
            if (contribution.unread) {
                unreadEntriesCount++;
                if ([contribution isKindOfClass:[Candy class]]) {
                    NSString *wrapId = [[(Candy *)contribution wrap] identifier];
                    if (wrapId) {
                        wrapCounters[wrapId] = @([wrapCounters[wrapId] unsignedIntegerValue] + 1);
                    }
                }
            }
        }
    }
    
    for (Contribution *contribution in updates) {
        if (contribution.valid) {
            [events addObject:[[WhatsUpEvent alloc] initWithEvent:WLEventUpdate contribution:contribution]];
            if (contribution.unread) {
                unreadEntriesCount++;
            }
        }
    }
    self.unreadEntriesCount = unreadEntriesCount;
    self.wrapCounters = [wrapCounters copy];
    [self resetEntries:events];
}

- (void)refreshCount:(void (^)(NSUInteger))success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self update:^{
        if (success) success(weakSelf.unreadEntriesCount);
    } failure:failure];
}

- (NSUInteger)unreadCandiesCountForWrap:(Wrap *)wrap {
    return [self.wrapCounters[wrap.identifier] unsignedIntegerValue];
}

- (void)notifier:(EntryNotifier*)notifier didAddEntry:(Entry *)entry {
    if ([[(Contribution *)entry contributor] current]) {
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self update:^{
        [weakSelf.broadcaster broadcast:@selector(whatsUpBroadcaster:updated:) object:weakSelf];
    } failure:^(NSError *error) {
    }];
}

- (void)notifier:(EntryNotifier*)notifier willDeleteEntry:(Entry *)entry {
    if ([[(Contribution*)entry contributor] current]) {
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self update:^{
        [weakSelf.broadcaster broadcast:@selector(whatsUpBroadcaster:updated:) object:weakSelf];
    } failure:^(NSError *error) {
    }];
}

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Entry *)entry {
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
