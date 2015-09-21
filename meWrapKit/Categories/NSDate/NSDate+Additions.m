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

+ (NSDate *)defaultBirtday {
	NSDateComponents* components = [NSDateComponents  new];
	[components setYear:2013];
	[components setMonth:06];
	[components setDay:19];
	components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	return [[NSCalendar currentCalendar] dateFromComponents:components];
}

+ (NSDate *)sinceWeekAgo {
    return [NSDate now:-WLTimeIntervalWeek];
}

+ (NSDate *)dayAgo {
    return [NSDate now:-WLDaySeconds];
}

- (NSDate *)beginOfDay {
    return [[NSCalendar currentCalendar] dateFromComponents:[self componentsBeginOfDay]];
}

- (NSDate *)endOfDay {
    return [[NSCalendar currentCalendar] dateFromComponents:[self componentsEndOfDay]];
}

- (void)getBeginOfDay:(NSDate *__autoreleasing *)beginOfDay endOfDay:(NSDate *__autoreleasing *)endOfDay {
    NSDateComponents* components = [self componentsBeginOfDay];
    if (beginOfDay != NULL) {
        *beginOfDay = [[NSCalendar currentCalendar] dateFromComponents:components];
    }
    components.hour = 23;
    components.minute = components.second = 59;
    if (endOfDay != NULL) {
        *endOfDay = [[NSCalendar currentCalendar] dateFromComponents:components];
    }
}

- (NSDateComponents *)componentsBeginOfDay {
	NSDateComponents* components = [self dayComponents];
    components.hour = components.minute = components.second = 0;
    return components;
}

- (NSDateComponents *)componentsEndOfDay {
    NSDateComponents* components = [self dayComponents];
    components.hour = 23;
    components.minute = components.second = 59;
    return components;
}

- (NSDateComponents *)dayComponents {
    return [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
}

- (BOOL)isSameDay:(NSDate *)date {
    return [[NSCalendar currentCalendar] isDate:self inSameDayAsDate:date];
}

- (BOOL)isSameHour:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    if ([calendar component:NSCalendarUnitHour fromDate:self] != [calendar component:NSCalendarUnitHour fromDate:date]) return NO;
    if ([calendar component:NSCalendarUnitDay fromDate:self] != [calendar component:NSCalendarUnitDay fromDate:date]) return NO;
    if ([calendar component:NSCalendarUnitMonth fromDate:self] != [calendar component:NSCalendarUnitMonth fromDate:date]) return NO;
    if ([calendar component:NSCalendarUnitYear fromDate:self] != [calendar component:NSCalendarUnitYear fromDate:date]) return NO;
    return YES;
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
		return [self stringWithDateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterShortStyle];
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
        return [self stringWithDateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterShortStyle];
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
