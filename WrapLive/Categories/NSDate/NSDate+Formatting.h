//
//  NSDate+Formatting.h
//  Riot
//
//  Created by Igor Fedorchuk on 30.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Formatting)

+ (NSString*)defaultDateFormat;

+ (void)setDefaultDateFormat:(NSString*)dateFormat;

+ (NSDateFormatter *)formatter;

+ (NSDateFormatter *)formatterWithDateFormat:(NSString*)dateFormat;

+ (NSDate *)defaultBirtday;

- (NSString*)stringWithFormat:(NSString*)dateFormat;

- (NSString*)string;

- (NSDate *)beginOfDay;

- (NSDate *)endOfDay;

- (BOOL)isSameDay:(NSDate*)date;

- (BOOL)isToday;

@end

@interface NSDateFormatter (DateFormatting)

- (NSDate *)dateFromString:(NSString *)string withFormat:(NSString*)dateFormat;

- (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString*)dateFormat;

@end

@interface NSString (DateFormatting)

- (NSDate*)dateWithFormat:(NSString*)dateFormat;

- (NSDate*)date;

@end
