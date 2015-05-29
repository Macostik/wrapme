//
//  NSDate+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 05.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSDate+Additions.h"
#import "NSDate+Formatting.h"
#import <objc/runtime.h>
#import "WLAPIRequest.h"
#import "UIDevice+SystemVersion.h"

//static NSString *WLTimeIntervalNameMinute = @"minute";
//static NSString *WLTimeIntervalNameHour = @"hour";
//static NSString *WLTimeIntervalNameDay = @"day";
//static NSString *WLTimeIntervalNameWeek = @"week";
//static NSString *WLTimeIntervalNameMonth = @"month";
//static NSString *WLTimeIntervalNameYear = @"year";
//static NSString *WLTimeIntervalLessThanMinute = @"less than 1 minute ago";
//static NSString *WLTimeIntervalNameYesterday = @"yesterday";
//static NSString *WLTimeIntervalNameToday = @"today";
static NSInteger WLDaySeconds = 24*60*60;

@implementation NSDate (Additions)

static inline NSCalendar* NSCurrentCalendar() {
    static NSCalendar* calendar = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = [NSCalendar currentCalendar];
    });
    return calendar;
}

+ (NSDate *)defaultBirtday {
	NSDateComponents* components = [NSDateComponents  new];
	[components setYear:2013];
	[components setMonth:06];
	[components setDay:19];
	components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	return [NSCurrentCalendar() dateFromComponents:components];
}

+ (NSDate *)sinceWeekAgo {
    return [NSDate now:-WLTimeIntervalWeek];
}

+ (NSDate *)dayAgo {
    return [NSDate now:-WLDaySeconds];
}

- (NSDate *)beginOfDay {
    return [NSCurrentCalendar() dateFromComponents:[self componentsBeginOfDay]];
}

- (NSDate *)endOfDay {
    return [NSCurrentCalendar() dateFromComponents:[self componentsEndOfDay]];
}

- (void)getBeginOfDay:(NSDate *__autoreleasing *)beginOfDay endOfDay:(NSDate *__autoreleasing *)endOfDay {
    NSDateComponents* components = [self componentsBeginOfDay];
    if (beginOfDay != NULL) {
        *beginOfDay = [NSCurrentCalendar() dateFromComponents:components];
    }
    components.hour = 23;
    components.minute = components.second = 59;
    if (endOfDay != NULL) {
        *endOfDay = [NSCurrentCalendar() dateFromComponents:components];
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
    return [NSCurrentCalendar() components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
}

- (BOOL)isSameDay:(NSDate *)date {
    if (ABS([self timeIntervalSinceDate:date]) > WLTimeIntervalDay) return NO;
    if (SystemVersionGreaterThanOrEqualTo8()) {
        NSCalendar *calendar = NSCurrentCalendar();
        if ([calendar component:NSDayCalendarUnit fromDate:self] != [calendar component:NSDayCalendarUnit fromDate:date]) return NO;
        if ([calendar component:NSMonthCalendarUnit fromDate:self] != [calendar component:NSMonthCalendarUnit fromDate:date]) return NO;
        if ([calendar component:NSYearCalendarUnit fromDate:self] != [calendar component:NSYearCalendarUnit fromDate:date]) return NO;
        return YES;
    } else {
        return [self isSameDayComponents:[date dayComponents]];
    }
}

- (BOOL)isSameDayComponents:(NSDateComponents *)c {
    if (SystemVersionGreaterThanOrEqualTo8()) {
        NSCalendar *calendar = NSCurrentCalendar();
        if ([calendar component:NSDayCalendarUnit fromDate:self] != c.day) return NO;
        if ([calendar component:NSMonthCalendarUnit fromDate:self] != c.month) return NO;
        if ([calendar component:NSYearCalendarUnit fromDate:self] != c.year) return NO;
    } else {
        NSDateComponents* c1 = [self dayComponents];
        if (c1.day != c.day) return NO;
        if (c1.month != c.month) return NO;
        if (c1.year != c.year) return NO;
    }
    return YES;
}

- (BOOL)isSameHour:(NSDate *)date {
    if (SystemVersionGreaterThanOrEqualTo8()) {
        NSCalendar *calendar = NSCurrentCalendar();
        if ([calendar component:NSHourCalendarUnit fromDate:self] != [calendar component:NSHourCalendarUnit fromDate:date]) return NO;
        if ([calendar component:NSDayCalendarUnit fromDate:self] != [calendar component:NSDayCalendarUnit fromDate:date]) return NO;
        if ([calendar component:NSMonthCalendarUnit fromDate:self] != [calendar component:NSMonthCalendarUnit fromDate:date]) return NO;
        if ([calendar component:NSYearCalendarUnit fromDate:self] != [calendar component:NSYearCalendarUnit fromDate:date]) return NO;
    } else {
        NSCalendarUnit units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit;
        ;
        NSCalendar* calendar = NSCurrentCalendar();
        NSDateComponents* c1 = [calendar components:units fromDate:self];
        NSDateComponents* c2 = [calendar components:units fromDate:date];
        if (c1.hour != c2.hour) return NO;
        if (c1.day != c2.day) return NO;
        if (c1.month != c2.month) return NO;
        if (c1.year != c2.year) return NO;
    }
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
		return [self stringWithFormat:[NSString stringWithFormat:@"MMMM d, yyyy '%@' h:mma", WLLS(@"at")]];
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
        return [self stringWithFormat:[NSString stringWithFormat:@"MMMM d, yyyy '%@' h:mma", WLLS(@"at")]];
    } else {
        NSTimeInterval value = 0;
        NSString* name = nil;
        if ((value = interval / WLTimeIntervalDay) >= 2) {
            return [NSString stringWithFormat:WLLS(@"formatted_calendar_units_ago_at_time"), value, WLLS(@"day"), [self stringWithFormat:@"h:mma"]];
        } else {
            name = [self isToday] ? WLLS(@"today") : WLLS(@"yesterday");
            return [NSString stringWithFormat:WLLS(@"formatted_day_at_time"), name, [self stringWithFormat:@"h:mma"]];
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
