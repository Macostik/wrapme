//
//  NSDate+Additions.m
//  Riot
//
//  Created by Igor Fedorchuk on 30.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDate+Formatting.h"

@implementation NSDate (Formatting)

static NSString* _defaultFormat = @"MMM d, yyyy";

+ (NSString*)defaultFormat {
	return _defaultFormat;
}

+ (void)setDefaultFormat:(NSString*)format {
	_defaultFormat = format;
}

static NSMutableDictionary* formatters = nil;

+ (NSDateFormatter *)formatter {
    return [self formatterWithDateFormat:_defaultFormat];
}

+ (NSDateFormatter *)formatterWithDateFormat:(NSString *)format {
    if (!formatters) {
        formatters = [NSMutableDictionary dictionary];
    }
    
    NSDateFormatter* formatter = [formatters objectForKey:format];
    
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = format;
		formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
        [formatter setAMSymbol:@"am"];
        [formatter setPMSymbol:@"pm"];
        [formatters setObject:formatter forKey:format];
    }
    
    return formatter;
}

- (NSString *)stringWithFormat:(NSString *)format {
    return [[NSDate formatterWithDateFormat:format] stringFromDate:self withFormat:format];
}

- (NSString *)stringWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone {
	return [[NSDate formatterWithDateFormat:format] stringFromDate:self withFormat:format timeZone:timeZone];
}

- (NSString *)GMTStringWithFormat:(NSString *)format {
	return [self stringWithFormat:format timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (NSString *)string {
    return [self stringWithFormat:[NSDate defaultFormat]];
}

- (NSString *)stringWithTimeZone:(NSTimeZone *)timeZone {
	return [self stringWithFormat:[NSDate defaultFormat] timeZone:timeZone];
}

- (NSString *)GMTString {
	return [self stringWithTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

@end

@implementation NSDateFormatter (DateFormatting)

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
    return [[NSDate formatterWithDateFormat:format] dateFromString:self withFormat:format];
}

- (NSDate *)dateWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone {
	return [[NSDate formatterWithDateFormat:format] dateFromString:self withFormat:format timeZone:timeZone];
}

- (NSDate *)GMTDateWithFormat:(NSString *)format {
	return [self dateWithFormat:format timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (NSDate *)date {
    return [self dateWithFormat:[NSDate defaultFormat]];
}

- (NSDate *)dateWithTimeZone:(NSTimeZone *)timeZone {
	return [self dateWithFormat:[NSDate defaultFormat] timeZone:timeZone];
}

- (NSDate *)GMTDate {
	return [self dateWithTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

@end
