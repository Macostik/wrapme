//
//  NSDate+Additions.m
//  Riot
//
//  Created by Igor Fedorchuk on 30.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDate+Formatting.h"

@implementation NSDate (Formatting)

static NSString* _defaultDateFormat = @"ddMMYYYY";

+ (NSString*)defaultDateFormat {
	return _defaultDateFormat;
}

+ (void)setDefaultDateFormat:(NSString*)dateFormat {
	_defaultDateFormat = dateFormat;
}

static NSMutableDictionary* formatters = nil;

+ (NSDateFormatter *)formatter {
    return [self formatterWithDateFormat:_defaultDateFormat];
}

+ (NSDateFormatter *)formatterWithDateFormat:(NSString *)dateFormat {
    if (!formatters) {
        formatters = [NSMutableDictionary dictionary];
    }
    
    NSDateFormatter* formatter = [formatters objectForKey:dateFormat];
    
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = dateFormat;
        [formatters setObject:formatter forKey:dateFormat];
    }
    
    return formatter;
}

+ (NSDate *)defaultBirtday {
	NSDateComponents* components = [NSDateComponents  new];
	[components setYear:2013];
	[components setMonth:06];
	[components setDay:19];
	return [[NSCalendar currentCalendar] dateFromComponents:components];
}

- (NSString *)stringWithFormat:(NSString *)dateFormat {
    return [[NSDate formatterWithDateFormat:dateFormat] stringFromDate:self withFormat:dateFormat];
}

- (NSString *)stringWithFormat:(NSString *)dateFormat timeZone:(NSTimeZone *)timeZone {
	return [[NSDate formatterWithDateFormat:dateFormat] stringFromDate:self withFormat:dateFormat timeZone:timeZone];
}

- (NSString *)GMTStringWithFormat:(NSString *)dateFormat {
	return [self stringWithFormat:dateFormat timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (NSString *)string {
    return [self stringWithFormat:[NSDate defaultDateFormat]];
}

- (NSString *)stringWithTimeZone:(NSTimeZone *)timeZone {
	return [self stringWithFormat:[NSDate defaultDateFormat] timeZone:timeZone];
}

- (NSString *)GMTString {
	return [self stringWithTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
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

@end

@implementation NSDateFormatter (DateFormatting)

- (NSDate *)dateFromString:(NSString *)string withFormat:(NSString*)dateFormat {
	return [self dateFromString:string withFormat:dateFormat timeZone:[NSTimeZone localTimeZone]];
}

- (NSDate *)dateFromString:(NSString *)string withFormat:(NSString*)dateFormat timeZone:(NSTimeZone *)timeZone {
    self.dateFormat = dateFormat;
	self.timeZone = timeZone;
    return [self dateFromString:string];
}

- (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString*)dateFormat {
	return [self stringFromDate:date withFormat:dateFormat timeZone:[NSTimeZone localTimeZone]];
}

- (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString *)dateFormat timeZone:(NSTimeZone *)timeZone {
	self.dateFormat = dateFormat;
	self.timeZone = timeZone;
    return [self stringFromDate:date];
}

@end

@implementation NSString (DateFormatting)

- (NSDate *)dateWithFormat:(NSString *)dateFormat {
    return [[NSDate formatterWithDateFormat:dateFormat] dateFromString:self withFormat:dateFormat];
}

- (NSDate *)dateWithFormat:(NSString *)dateFormat timeZone:(NSTimeZone *)timeZone {
	return [[NSDate formatterWithDateFormat:dateFormat] dateFromString:self withFormat:dateFormat timeZone:timeZone];
}

- (NSDate *)GMTDateWithFormat:(NSString *)dateFormat {
	return [self dateWithFormat:dateFormat timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (NSDate *)date {
    return [self dateWithFormat:[NSDate defaultDateFormat]];
}

- (NSDate *)dateWithTimeZone:(NSTimeZone *)timeZone {
	return [self dateWithFormat:[NSDate defaultDateFormat] timeZone:timeZone];
}

- (NSDate *)GMTDate {
	return [self dateWithTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

@end
