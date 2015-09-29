//
//  NSDate+Additions.m
//  meWrap
//
//  Created by Ravenpod on 05.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSDate+Additions.h"
#import "NSDate+Formatting.h"
#import <objc/runtime.h>
#import "WLAPIRequest.h"
#import "UIDevice+SystemVersion.h"
#import "WLLocalization.h"
#import "WLSession.h"

static NSInteger WLDaySeconds = 24*60*60;

@implementation NSDate (Additions)

+ (NSDate *)dayAgo {
    return [NSDate now:-WLDaySeconds];
}

- (NSDate *)beginOfDay {
    NSDate *beginOfDay = nil;
    [self getBeginOfDay:&beginOfDay endOfDay:NULL];
    return beginOfDay;
}

- (NSDate *)endOfDay {
    NSDate *endOfDay = nil;
    [self getBeginOfDay:NULL endOfDay:&endOfDay];
    return endOfDay;
}

- (void)getBeginOfDay:(NSDate *__autoreleasing *)beginOfDay endOfDay:(NSDate *__autoreleasing *)endOfDay {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
    if (beginOfDay != NULL) {
        components.hour = components.minute = components.second = 0;
        *beginOfDay = [[NSCalendar currentCalendar] dateFromComponents:components];
    }
    if (endOfDay != NULL) {
        components.hour = 23;
        components.minute = 59;
        components.nanosecond = 59999999999;
        *endOfDay = [[NSCalendar currentCalendar] dateFromComponents:components];
    }
}

- (void)getBeginOfDay:(NSDate *__autoreleasing *)beginOfDay beginOfNextDay:(NSDate *__autoreleasing *)beginOfNextDay {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
    components.hour = components.minute = components.second = 0;
    if (beginOfDay != NULL) {
        *beginOfDay = [calendar dateFromComponents:components];
        if (beginOfNextDay != NULL) {
            *beginOfNextDay = [*beginOfDay dateByAddingTimeInterval:WLDaySeconds];
        }
    } else {
        if (beginOfNextDay != NULL) {
            components.day += 1;
            *beginOfNextDay = [calendar dateFromComponents:components];
        }
    }
}

- (BOOL)isSameDay:(NSDate *)date {
    return [[NSCalendar currentCalendar] isDate:self inSameDayAsDate:date];
}

- (BOOL)isToday {
	return [self isSameDay:[NSDate now]];
}

- (NSTimeInterval)timestamp {
	return [self timeIntervalSince1970];
}

- (NSString *)timeAgoString {
    
    NSTimeInterval interval = ABS([self timeIntervalSinceDate:[NSDate now]]);
    
	if (interval >= WLTimeIntervalWeek) {
		return [self stringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
	} else {
		NSTimeInterval value = 0;
		NSString* name = nil;
		if ((value = interval / WLTimeIntervalDay) >= 1) {
			name = WLLS(@"day");
		} else if ((value = interval / WLTimeIntervalHour) >= 1) {
			name = WLLS(@"hour");
		} else if ((value = interval / WLTimeIntervalMinute) >= 1) {
			name = WLLS(@"minute");
		} else {
			return WLLS(@"less_than_minute_ago");
		}
        value = floor(value);
		return [NSString stringWithFormat:WLLS(@"formatted_calendar_units_ago"), value, name, (value == 1 ? @"":WLLS(@"plural_ending"))];
	}
}

- (NSString *)timeAgoStringAtAMPM {
    NSTimeInterval interval = ABS([self timeIntervalSinceDate:[NSDate now]]);
    if (interval >= WLTimeIntervalWeek) {
        return [self stringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    } else {
        NSTimeInterval value = 0;
        NSString* name = nil;
        if ((value = interval / WLTimeIntervalDay) >= 2) {
            return [NSString stringWithFormat:WLLS(@"formatted_calendar_units_ago_at_time"), value, WLLS(@"day"), [self stringWithTimeStyle:NSDateFormatterShortStyle]];
        } else {
            name = [self isToday] ? WLLS(@"today") : WLLS(@"yesterday");
            return [NSString stringWithFormat:WLLS(@"formatted_day_at_time"), name, [self stringWithTimeStyle:NSDateFormatterShortStyle]];
        }
    }
}

- (BOOL)earlier:(NSDate *)date {
    return [self timeIntervalSinceDate:date] < 0;
}

- (BOOL)later:(NSDate *)date {
    return [self timeIntervalSinceDate:date] > 0;
}

- (BOOL)match:(NSDate *)date {
    return [self timeIntervalSinceDate:date] == 0;
}

- (NSComparisonResult)timestampCompare:(NSDate *)date {
    NSTimeInterval t1 = self.timestamp;
    NSTimeInterval t2 = date.timestamp;
    if (t1 < t2) {
        return NSOrderedAscending;
    } else if (t1 > t2) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

@end

@implementation NSDate (ServerTimeDifference)

+ (void)trackServerTime:(NSDate *)serverTime {
    WLSession.serverTimeDifference = serverTime ? [serverTime timeIntervalSinceNow] : 0;
}

+ (NSDate*)now {
    return [self dateWithTimeIntervalSinceNow:WLSession.serverTimeDifference];
}

+ (instancetype)now:(NSTimeInterval)offset {
    return [self dateWithTimeIntervalSinceNow:WLSession.serverTimeDifference + offset];
}

+ (instancetype)dateWithTimestamp:(NSTimeInterval)timestamp {
    return [self dateWithTimeIntervalSince1970:WLSession.serverTimeDifference + timestamp];
}

@end
