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

- (instancetype)init {
    self = [super init];
    if (self) {
        self.set = [NSMutableOrderedSet orderedSet];
        self.keyedGroups = [NSMutableDictionary dictionary];
        self.dateFormat = @"MMM dd, yyyy";
    }
    return self;
}

- (void)setCandies:(NSOrderedSet *)candies {
    [self clear];
    [self addCandies:candies];
}

- (WLGroup *)groupNamed:(NSString *)name {
    return [self groupNamed:name created:NULL];
}

- (WLGroup *)groupNamed:(NSString *)name created:(BOOL *)created {
    WLGroup* group = [self.keyedGroups objectForKey:name];
    if (!group) {
        group = [WLGroup date];
        group.name = name;
        [self.keyedGroups setObject:group forKey:name];
        [self.set addObject:group];
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
        NSString* name = [candy.updatedAt stringWithFormat:@"MMM dd, yyyy"];
        WLGroup* group = [self groupNamed:name created:created];
        [group addCandy:candy];
    }
}

- (void)removeCandy:(WLCandy *)candy {
    BOOL removed = NO;
    for (WLGroup* group in self.set) {
        if ([group.candies containsObject:candy]) {
            [group.candies removeObject:candy];
            removed = YES;
        }
    }
    if (removed) {
        [self.delegate groupedSetGroupsChanged:self];
    }
}

- (void)clear {
    for (WLGroup* group in self.set) {
        group.message = nil;
        [group.candies removeAllObjects];
    }
}

- (void)sort:(WLCandy*)candy {
    for (WLGroup* group in self.set) {
        if ([group.candies containsObject:candy]) {
            [group sort];
        }
    }
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
    }
    return self;
}

- (BOOL)addCandies:(NSOrderedSet *)candies {
    return [self addCandies:candies sort:NO];
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
        if (added) {
            [self.delegate groupsChanged:self];
        }
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
    if ([candy isMessage]) {
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
