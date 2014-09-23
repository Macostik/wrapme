//
//  NSDate+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 05.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSDate+Additions.h"
#import "NSDate+Formatting.h"
#import "WLSupportFunctions.h"
#import <objc/runtime.h>
#import "WLAPIRequest.h"
#import "UIDevice+SystemVersion.h"

static const NSTimeInterval WLTimeIntervalMinute = 60;
static const NSTimeInterval WLTimeIntervalHour = 3600;
static const NSTimeInterval WLTimeIntervalDay = 86400;
static const NSTimeInterval WLTimeIntervalWeek = 604800;

static NSString *WLTimeIntervalNameMinute = @"minute";
static NSString *WLTimeIntervalNameHour = @"hour";
static NSString *WLTimeIntervalNameDay = @"day";
static NSString *WLTimeIntervalNameWeek = @"week";
static NSString *WLTimeIntervalNameMonth = @"month";
static NSString *WLTimeIntervalNameYear = @"year";
static NSString *WLTimeIntervalLessThanMinute = @"less than 1 minute ago";
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
    NSDateComponents* components = [self dayComponents];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    if (beginOfDay != NULL) {
        *beginOfDay = [NSCurrentCalendar() dateFromComponents:components];
    }
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    if (endOfDay != NULL) {
        *endOfDay = [NSCurrentCalendar() dateFromComponents:components];
    }
}

- (NSDateComponents *)componentsBeginOfDay {
	NSDateComponents* components = [self dayComponents];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    return components;
}

- (NSDateComponents *)componentsEndOfDay {
    NSDateComponents* components = [self dayComponents];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    return components;
}

- (NSDateComponents *)dayComponents {
    return [NSCurrentCalendar() components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
}

- (BOOL)isSameDay:(NSDate *)date {
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
    NSDateComponents* c1 = [self dayComponents];
	return c1.year == c.year && c1.month == c.month && c1.day == c.day;
}

- (BOOL)isSameHour:(NSDate *)date {
    NSCalendarUnit units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit;
    ;
    NSCalendar* calendar = NSCurrentCalendar();
    NSDateComponents* c1 = [calendar components:units fromDate:self];
    NSDateComponents* c2 = [calendar components:units fromDate:date];
	return c1.year == c2.year && c1.month == c2.month && c1.day == c2.day && c1.hour == c2.hour;
}

- (BOOL)isToday {
	return [self isSameDay:[NSDate now]];
}

- (NSTimeInterval)timestamp {
	return [self timeIntervalSince1970];
}

- (NSString *)timeAgoString {
	NSTimeInterval interval = ABS([self timeIntervalSinceNow]);
	if (interval >= WLTimeIntervalWeek) {
		return [self stringWithFormat:@"MMMM d, yyyy 'at' hh:mma"];
	} else {
		NSTimeInterval value = 0;
		NSString* name = nil;
		if ((value = interval / WLTimeIntervalDay) >= 1) {
			name = WLTimeIntervalNameDay;
		} else if ((value = interval / WLTimeIntervalHour) >= 1) {
			name = WLTimeIntervalNameHour;
		} else if ((value = interval / WLTimeIntervalMinute) >= 1) {
			name = WLTimeIntervalNameMinute;
		} else {
			return WLTimeIntervalLessThanMinute;
		}
        value = floor(value);
		return [NSString stringWithFormat:@"%f %@%@ ago", value, name, (value == 1 ? @"":@"s")];
	}
}

@end
