//
//  NSDate+Additions.m
//  Riot
//
//  Created by Igor Fedorchuk on 30.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDate+Formatting.h"

@implementation NSDate (Formatting)

- (NSString *)stringWithFormat:(NSString *)format {
    return [[NSDateFormatter formatterWithDateFormat:format] stringFromDate:self withFormat:format];
}

- (NSString *)stringWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone {
	return [[NSDateFormatter formatterWithDateFormat:format] stringFromDate:self withFormat:format timeZone:timeZone];
}

- (NSString *)GMTStringWithFormat:(NSString *)format {
	return [self stringWithFormat:format timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (NSString *)string {
    return [self stringWithFormat:[NSDateFormatter defaultFormat]];
}

- (NSString *)stringWithTimeZone:(NSTimeZone *)timeZone {
	return [self stringWithFormat:[NSDateFormatter defaultFormat] timeZone:timeZone];
}

- (NSString *)GMTString {
	return [self stringWithTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (NSString *)stringWithTimeStyle:(NSDateFormatterStyle)timeStyle {
    return [self stringWithDateStyle:NSDateFormatterNoStyle timeStyle:timeStyle];
}

- (NSString *)stringWithDateStyle:(NSDateFormatterStyle)dateStyle {
    return [self stringWithDateStyle:dateStyle timeStyle:NSDateFormatterNoStyle];
}

- (NSString *)stringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle {
    return [self stringWithDateStyle:dateStyle timeStyle:timeStyle relative:NO];
}

- (NSString *)stringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle relative:(BOOL)relative {
    return [[NSDateFormatter formatterWithDateStyle:dateStyle timeStyle:timeStyle relative:relative] stringFromDate:self];
}

@end

@implementation NSDateFormatter (DateFormatting)

static NSString* _defaultFormat = @"MMM d, yyyy";

+ (NSString*)defaultFormat {
    return _defaultFormat;
}

+ (void)setDefaultFormat:(NSString*)format {
    _defaultFormat = format;
}

static NSMutableDictionary* _formatters = nil;

+ (NSMutableDictionary *)formatters {
    if (!_formatters) {
        _formatters = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSSystemTimeZoneDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [_formatters removeAllObjects];
        }];
    }
    return _formatters;
}

+ (NSDateFormatter *)formatter {
    return [self formatterWithDateFormat:_defaultFormat];
}

+ (NSDateFormatter *)formatterWithDateFormat:(NSString *)format {
    NSMutableDictionary *formatters = [self formatters];
    
    NSDateFormatter* formatter = [formatters objectForKey:format];
    
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = format;
        [formatter setAMSymbol:@"am"];
        [formatter setPMSymbol:@"pm"];
        [formatters setObject:formatter forKey:format];
    }
    
    return formatter;
}

+ (NSDateFormatter *)formatterWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle {
    return [self formatterWithDateStyle:dateStyle timeStyle:timeStyle relative:NO];
}

+ (NSDateFormatter *)formatterWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle relative:(BOOL)relative {
    NSMutableDictionary *formatters = [self formatters];
    
    NSString *formatterKey = [NSString stringWithFormat:@"%lu-%lu-%d", (unsigned long)dateStyle, (unsigned long)timeStyle, relative];
    NSDateFormatter* formatter = [formatters objectForKey:formatterKey];
    
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = dateStyle;
        formatter.timeStyle = timeStyle;
        formatter.doesRelativeDateFormatting = relative;
        [formatters setObject:formatter forKey:formatterKey];
    }
    
    return formatter;
}

- (NSDate *)dateFromString:(NSString *)string withFormat:(NSString*)format {
	return [self dateFromString:string withFormat:format timeZone:[NSTimeZone localTimeZone]];
}

- (NSDate *)dateFromString:(NSString *)string withFormat:(NSString*)format timeZone:(NSTimeZone *)timeZone {
    self.dateFormat = format;
	self.timeZone = timeZone;
    return [self dateFromString:string];
}

- (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString*)format {
	return [self stringFromDate:date withFormat:format timeZone:[NSTimeZone localTimeZone]];
}

- (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone {
	self.dateFormat = format;
	self.timeZone = timeZone;
    return [self stringFromDate:date];
}

@end

@implementation NSString (DateFormatting)

- (NSDate *)dateWithFormat:(NSString *)format {
    return [[NSDateFormatter formatterWithDateFormat:format] dateFromString:self withFormat:format];
}

- (NSDate *)dateWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone {
	return [[NSDateFormatter formatterWithDateFormat:format] dateFromString:self withFormat:format timeZone:timeZone];
}

- (NSDate *)GMTDateWithFormat:(NSString *)format {
	return [self dateWithFormat:format timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (NSDate *)date {
    return [self dateWithFormat:[NSDateFormatter defaultFormat]];
}

- (NSDate *)dateWithTimeZone:(NSTimeZone *)timeZone {
	return [self dateWithFormat:[NSDateFormatter defaultFormat] timeZone:timeZone];
}

- (NSDate *)GMTDate {
	return [self dateWithTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

@end
