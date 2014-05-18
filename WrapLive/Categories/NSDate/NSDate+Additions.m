//
//  NSDate+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 05.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSDate+Additions.h"
#import "NSDate+Formatting.h"

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
static NSString *WLTimeIntervalLessThanMinute = @"less than minute ago";

@implementation NSDate (Additions)

+ (NSDate *)defaultBirtday {
	NSDateComponents* components = [NSDateComponents  new];
	[components setYear:2013];
	[components setMonth:06];
	[components setDay:19];
	components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	return [[NSCalendar currentCalendar] dateFromComponents:components];
}

- (NSDate *)beginOfDay {
    return [[NSCalendar currentCalendar] dateFromComponents:[self componentsBeginOfDay]];
}

- (NSDate *)endOfDay {
    return [[NSCalendar currentCalendar] dateFromComponents:[self componentsEndOfDay]];
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
	NSCalendarUnit units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    return [[NSCalendar currentCalendar] components:units fromDate:self];
}

- (BOOL)isSameDay:(NSDate *)date {
	return [[self string] isEqualToString:[date string]];
}

- (BOOL)isToday {
	return [self isSameDay:[NSDate date]];
}

- (NSString *)timeAgoString {
	NSTimeInterval interval = ABS([self timeIntervalSinceNow]);
	if (interval >= WLTimeIntervalWeek) {
		return [self stringWithFormat:@"MMMM d, yyyy 'at' hh:mma"];
	} else {
		NSInteger value = 0;
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
		return [NSString stringWithFormat:@"%d %@%@ ago", value, name, (value == 1 ? @"":@"s")];
	}
}

@end
