//
//  WLMessagesCounter.m
//  meWrap
//
//  Created by Ravenpod on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLMessagesCounter.h"

@interface WLMessagesCounter () <WLEntryNotifyReceiver>

@property (strong, nonatomic) NSDictionary *counts;

@property (strong, nonatomic) NSFetchRequest *request;

@end

@implementation WLMessagesCounter {
    BOOL updating;
}

+ (instancetype)instance {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[WLMessage notifier] addReceiver:self];
        
        NSExpressionDescription *count = [[NSExpressionDescription alloc] init];
        [count setExpression:[NSExpression expressionForFunction:@"count:" arguments:@[[NSExpression expressionForEvaluatedObject]]]];
        [count setName:@"count"];
        [count setExpressionResultType:NSDecimalAttributeType];
        
        self.request = [[WLMessage fetchRequest] groupedBy:@[@"wrap"] fetch:@[count, @"wrap"]];
        
        [self update:nil];
    }
    return self;
}

- (void)setCounts:(NSDictionary *)counts {
    
    if (![_counts isEqualToDictionary:counts]) {
        _counts = counts;
        [self broadcast:@selector(counterDidChange:)];
    }
}

- (void)update:(WLBlock)completionHandler {
    if (updating) {
        return;
    }
    updating = YES;
    __weak typeof(self)weakSelf = self;
    NSDate *dayAgo = [NSDate dayAgo];
    self.request.predicate = [NSPredicate predicateWithFormat:@"unread = YES AND createdAt >= %@", dayAgo];
    [self.request execute:^(NSArray *array) {
        NSMutableDictionary *counts = [NSMutableDictionary dictionary];
        for (NSDictionary *data in array) {
            NSManagedObjectID *identifier = data[@"wrap"];
            if (identifier) {
                [counts setObject:data[@"count"] forKey:identifier];
            }
        }
        weakSelf.counts = counts;
        if (completionHandler) completionHandler();
        updating = NO;
    } failure:^(NSError *error) {
        updating = NO;
    }];
}

- (NSUInteger)countForWrap:(WLWrap *)wrap {
    return [[self.counts objectForKey:[wrap objectID]] unsignedIntegerValue];
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didAddEntry:(WLEntry *)entry {
    if (entry.unread) {
        [self update:nil];
    }
}

- (void)notifier:(WLEntryNotifier *)notifier willDeleteEntry:(WLEntry *)entry {
    
}

@end
