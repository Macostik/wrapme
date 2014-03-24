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

- (NSString *)stringWithFormat:(NSString *)dateFormat {
    return [[NSDate formatterWithDateFormat:dateFormat] stringFromDate:self withFormat:dateFormat];
}

- (NSString *)string {
    return [self stringWithFormat:[NSDate defaultDateFormat]];
}

@end

@implementation NSDateFormatter (DateFormatting)

- (NSDate *)dateFromString:(NSString *)string withFormat:(NSString*)dateFormat {
    self.dateFormat = dateFormat;
    return [self dateFromString:string];
}

- (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString*)dateFormat {
    self.dateFormat = dateFormat;
    return [self stringFromDate:date];
}

@end

@implementation NSString (DateFormatting)

- (NSDate *)dateWithFormat:(NSString *)dateFormat {
    return [[NSDate formatterWithDateFormat:dateFormat] dateFromString:self withFormat:dateFormat];
}

- (NSDate *)date {
    return [self dateWithFormat:[NSDate defaultDateFormat]];
}

@end
