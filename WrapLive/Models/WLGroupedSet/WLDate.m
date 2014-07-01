//
//  WLWrapDate.m
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLDate.h"
#import "WLCandy+Extended.h"
#import "NSOrderedSet+Additions.h"
#import "NSDate+Additions.h"
#import "NSDate+Formatting.h"
#import "WLSupportFunctions.h"
#import "WLEntry+Extended.h"

@implementation WLDate

+ (instancetype)dateWithDate:(NSDate *)date {
    WLDate* _date = [[self alloc] init];
    _date.date = date;
    return _date;
}

+ (NSMutableOrderedSet *)dates:(NSOrderedSet *)entries dates:(NSMutableOrderedSet *)dates {
    NSMutableDictionary* ds = [NSMutableDictionary dictionary];
    for (WLCandy* candy in entries) {
        if (candy.updatedAt) {
            NSString* name = [candy.updatedAt stringWithFormat:@"MMM dd, yyyy"];
            WLDate* date = [ds objectForKey:name];
            if (!date) {
                date = [WLDate dateWithDate:candy.updatedAt];
                date.name = name;
                [ds setObject:date forKey:name];
                [dates addObject:date];
            }
            [date addCandy:candy];
        }
    }
    return dates;
}

+ (NSMutableOrderedSet *)dates:(NSOrderedSet *)entries {
    return [self dates:entries dates:[NSMutableOrderedSet orderedSet]];
}

- (NSMutableOrderedSet *)candies {
    if (!_candies) {
        _candies = [NSMutableOrderedSet orderedSet];
    }
    return _candies;
}

- (NSComparisonResult)compare:(WLDate *)date {
    return [self.date compare:date.date];
}

- (void)addCandies:(NSOrderedSet *)candies {
    return [self addCandies:candies sort:NO];
}

- (void)addCandies:(NSOrderedSet *)candies sort:(BOOL)sort {
    for (WLCandy *candy in candies) {
        [self addCandy:candy];
    }
    if (sort) {
        [self.candies sortEntries];
    }
}

- (void)addCandy:(WLCandy *)candy {
    [self addCandy:candy sort:NO];
}

- (void)addCandy:(WLCandy *)candy sort:(BOOL)sort {
    if ([candy isMessage]) {
        if (!self.containsMessage) {
            [self.candies addObject:candy];
            self.containsMessage = YES;
        }
    } else {
        [self.candies addObject:candy];
    }
    if (sort) {
        [self.candies sortEntries];
    }
}

@end

@implementation NSMutableOrderedSet (WLDate)

- (void)unionCandies:(NSOrderedSet *)candies {
    [WLDate dates:candies dates:self];
}

@end
