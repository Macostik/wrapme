//
//  WLServerTime.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLServerTime.h"

static NSString* WLServerTimeDeifference = @"WLServerTimeDeifference";

@implementation WLServerTime

static NSTimeInterval _difference = 0;

+ (NSTimeInterval)difference {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _difference = [[NSUserDefaults standardUserDefaults] doubleForKey:WLServerTimeDeifference];
    });
    return _difference;
}

+ (void)setDifference:(NSTimeInterval)interval {
    if (_difference != interval) {
        _difference = interval;
        [[NSUserDefaults standardUserDefaults] setDouble:interval forKey:WLServerTimeDeifference];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSDate*)current {
    return [NSDate dateWithTimeIntervalSinceNow:[self difference]];
}

+ (void)track:(NSDate *)serverTime {
    if (serverTime) {
        [WLServerTime setDifference:[serverTime timeIntervalSinceDate:[NSDate date]]];
    } else {
        [WLServerTime setDifference:0];
    }
}

@end

@implementation NSDate (WLServerTime)

+ (instancetype)serverTime {
    return [WLServerTime current];
}

@end
