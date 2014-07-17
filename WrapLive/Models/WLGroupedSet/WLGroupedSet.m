//
//  WLGroupedSet.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLGroupedSet.h"
#import "WLCandy+Extended.h"
#import "WLEntry+Extended.h"
#import "NSDate+Formatting.h"
#import "NSOrderedSet+Additions.h"
#import "NSDate+Additions.h"
#import "WLCandiesRequest.h"

@interface WLGroupedSet ()

@property (strong, nonatomic) NSMutableDictionary *keyedGroups;

@end

@implementation WLGroupedSet

- (instancetype)init {
    self = [super init];
    if (self) {
        self.set = [NSMutableOrderedSet orderedSet];
        self.keyedGroups = [NSMutableDictionary dictionary];
        self.dateFormat = @"MMM dd, yyyy";
        self.singleMessage = YES;
    }
    return self;
}

- (void)setCandies:(NSOrderedSet *)candies {
    [self clear];
    [self addCandies:candies];
}

- (WLGroup *)group:(NSDate *)date {
    return [self group:date created:NULL];
}

- (WLGroup *)group:(NSDate *)date created:(BOOL *)created {
    NSString* name = [date stringWithFormat:self.dateFormat];
    WLGroup* group = [self.keyedGroups objectForKey:name];
    if (!group) {
        group = [WLGroup date];
        group.date = date;
        group.singleMessage = self.singleMessage;
        group.name = name;
        [self.keyedGroups setObject:group forKey:name];
        [self.set addObject:group];
        [self.set sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
        if (created != NULL) {
            *created = YES;
        }
    }
    return group;
}

- (void)addCandies:(NSOrderedSet *)candies {
    BOOL created = NO;
    for (WLCandy* candy in candies) {
        if (candy.updatedAt) {
            [self addCandy:candy created:&created];
        }
    }
    if (created) {
        [self.delegate groupedSetGroupsChanged:self];
    }
}

- (void)addCandy:(WLCandy *)candy {
    BOOL created = NO;
    [self addCandy:candy created:&created];
    if (created) {
        [self.delegate groupedSetGroupsChanged:self];
    }
}

- (void)addCandy:(WLCandy *)candy created:(BOOL *)created {
    if (candy.updatedAt) {
        WLGroup* group = [self group:candy.updatedAt created:created];
        [group addEntry:candy];
    }
}

- (void)removeCandy:(WLCandy *)candy {
    __block BOOL removed = NO;
    __weak typeof(self)weakSelf = self;
    [self.set removeObjectsWhileEnumerating:^BOOL(WLGroup* group) {
        if ([group.entries containsObject:candy]) {
            [group.entries removeObject:candy];
            removed = YES;
            if (group.entries.nonempty) {
                return NO;
            }
            [weakSelf.keyedGroups removeObjectForKey:group.name];
            return YES;
        }
        return NO;
    }];
    if (removed) {
        [self.delegate groupedSetGroupsChanged:self];
    }
}

- (void)clear {
    [self.set removeAllObjects];
    [self.keyedGroups removeAllObjects];
}

- (void)sort:(WLCandy*)candy {
    BOOL created = NO;
    WLGroup* group = [self group:candy.updatedAt created:&created];
    if (!created && [group.entries containsObject:candy]) {
        [group sort];
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self.set removeObjectsWhileEnumerating:^BOOL(WLGroup* group) {
        if ([group.entries containsObject:candy]) {
            [group.entries removeObject:candy];
            if (group.entries.nonempty) {
                return NO;
            }
            [weakSelf.keyedGroups removeObjectForKey:group.name];
            return YES;
        }
        return NO;
    }];
    [group addEntry:candy];
    [group sort];
    [self.delegate groupedSetGroupsChanged:self];
}

- (void)sort {
    for (WLGroup* group in self.set) {
        [group sort];
    }
}

@end

@implementation WLGroup

+ (instancetype)date {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.offset = CGPointZero;
        self.request = [WLCandiesRequest request];
        self.request.sameDay = YES;
    }
    return self;
}

- (id)send:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLCandiesRequest* request = (id)self.request;
    request.wrap = [[self.entries firstObject] wrap];
    return [super send:success failure:failure];
}

- (BOOL)shouldAddEntry:(WLCandy*)entry {
    if (self.singleMessage && [entry isMessage]) {
        if (!self.message) {
            self.message = entry;
            return YES;
        } else if ([self.message.updatedAt compare:entry.updatedAt] == NSOrderedAscending) {
            [self.entries removeObject:self.message];
            self.message = entry;
            return YES;
        }
        return NO;
    } else {
        return YES;
    }
}

@end
