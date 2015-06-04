//
//  NSDate+Formatting.h
//  Riot
//
//  Created by Igor Fedorchuk on 30.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Formatting)

+ (NSString*)defaultFormat;

+ (void)setDefaultFormat:(NSString*)dateFormat;

+ (NSDateFormatter *)formatter;

+ (NSDateFormatter *)formatterWithDateFormat:(NSString*)dateFormat;

+ (NSDateFormatter *)formatterWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle;

+ (NSDateFormatter *)formatterWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle relative:(BOOL)relative;

- (NSString*)stringWithFormat:(NSString*)dateFormat;

- (NSString*)stringWithFormat:(NSString*)dateFormat timeZone:(NSTimeZone*)timeZone;

- (NSString*)GMTStringWithFormat:(NSString*)dateFormat;

- (NSString*)string;

- (NSString*)stringWithTimeZone:(NSTimeZone*)timeZone;

- (NSString*)GMTString;

- (NSString *)stringWithTimeStyle:(NSDateFormatterStyle)timeStyle;

- (NSString *)stringWithDateStyle:(NSDateFormatterStyle)dateStyle;

- (NSString *)stringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle;

- (NSString *)stringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle relative:(BOOL)relative;

@end

@interface NSDateFormatter (DateFormatting)

- (NSDate *)dateFromString:(NSString *)string withFormat:(NSString*)dateFormat;

- (NSDate *)dateFromString:(NSString *)string withFormat:(NSString*)dateFormat timeZone:(NSTimeZone*)timeZone;

- (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString*)dateFormat;

- (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString*)dateFormat timeZone:(NSTimeZone*)timeZone;

@end

@interface NSString (DateFormatting)

- (NSDate*)dateWithFormat:(NSString*)dateFormat;

- (NSDate*)dateWithFormat:(NSString*)dateFormat timeZone:(NSTimeZone*)timeZone;

- (NSDate*)GMTDateWithFormat:(NSString*)dateFormat;

- (NSDate*)date;

- (NSDate*)dateWithTimeZone:(NSTimeZone*)timeZone;

- (NSDate*)GMTDate;

@end
