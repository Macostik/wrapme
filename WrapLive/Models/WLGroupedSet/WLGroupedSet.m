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

@interface WLGroupedSet ()

@property (strong, nonatomic) NSMutableDictionary *keyedGroups;

@end

@implementation WLGroupedSet
{
    NSUInteger _count;
}

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

- (NSUInteger)count {
    return _count;
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
        NSUInteger count = [group.candies count];
        [group addCandy:candy];
        if ([group.candies count] > count) {
            ++_count;
        }
    }
}

- (void)removeCandy:(WLCandy *)candy {
    __block BOOL removed = NO;
    __weak typeof(self)weakSelf = self;
    [self.set removeObjectsWhileEnumerating:^BOOL(WLGroup* group) {
        if ([group.candies containsObject:candy]) {
            [group.candies removeObject:candy];
            removed = YES;
            if (group.candies.nonempty) {
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
    _count = 0;
    [self.set removeAllObjects];
    [self.keyedGroups removeAllObjects];
}

- (void)sort:(WLCandy*)candy {
    BOOL created = NO;
    WLGroup* group = [self group:candy.updatedAt created:&created];
    if (!created && [group.candies containsObject:candy]) {
        [group sort];
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self.set removeObjectsWhileEnumerating:^BOOL(WLGroup* group) {
        if ([group.candies containsObject:candy]) {
            [group.candies removeObject:candy];
            if (group.candies.nonempty) {
                return NO;
            }
            [weakSelf.keyedGroups removeObjectForKey:group.name];
            return YES;
        }
        return NO;
    }];
    [group addCandy:candy];
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
    WLGroup* _date = [[self alloc] init];
    return _date;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.candies = [NSMutableOrderedSet orderedSet];
        self.offset = CGPointZero;
    }
    return self;
}

- (BOOL)addCandies:(NSOrderedSet *)candies {
    return [self addCandies:candies sort:YES];
}

- (BOOL)addCandies:(NSOrderedSet *)candies sort:(BOOL)sort {
    BOOL added = NO;
    for (WLCandy *candy in candies) {
        if ([self addCandy:candy]) {
            added = YES;
        }
    }
    if (sort) {
        [self sort];
    } else if (added) {
        [self.delegate groupsChanged:self];
    }
    return added;
}

- (BOOL)addCandy:(WLCandy *)candy {
    return [self addCandy:candy sort:NO];
}

- (BOOL)addCandy:(WLCandy *)candy sort:(BOOL)sort {
    if ([self.candies containsObject:candy]) {
        return NO;
    }
    if (self.singleMessage && [candy isMessage]) {
        if (!self.message) {
            [self.candies addObject:candy];
            self.message = candy;
        } else if ([self.message.updatedAt compare:candy.updatedAt] == NSOrderedAscending) {
            [self.candies removeObject:self.message];
            [self.candies addObject:candy];
            self.message = candy;
        }
    } else {
        [self.candies addObject:candy];
    }
    if (sort) {
        [self sort];
    }
    return YES;
}

- (void)sort {
    [self.candies sortEntries];
    [self.delegate groupsChanged:self];
}

@end
