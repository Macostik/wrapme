//
//  NSString+Hash.m
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 4/3/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "NSString+Additions.h"
#import "NSObject+AssociatedObjects.h"

@implementation NSString (Additions)

- (BOOL)isValidEmail {
	NSString *emailRegex =
	@"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
	@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
	@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
	@"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
	@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
	@"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
	@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	
	return [emailTest evaluateWithObject:[self lowercaseString]];
}

- (BOOL)isValidUrl {
    NSString *urlRegEx = @"http(s)?://([\\w-]+\\.)+[\\w-]+(/[\\w- ./?%&amp;=]*)?";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:[self lowercaseString]];
}

- (NSString *)trim {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)empty {
	return (self.length == 0);
}

- (BOOL)nonempty {
	return (self.length > 0);
}

- (BOOL)matches:(NSString *)string, ... {
	BOOL matches = NO;
	va_list args;
	va_start(args, string);
	for (; string != nil; string = va_arg(args, id)) {
		if ((matches = [self isEqualToString:string])) break;
	}
	va_end(args);
	return matches;
}

- (CGFloat)heightWithFont:(UIFont *)font width:(CGFloat)width cachingKey:(char *)key {
    NSNumber* storedHeight = [self associatedObjectForKey:key];
    if (!storedHeight) {
        CGFloat height  = ceilf([self boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                           options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size.height);
        storedHeight = @(height);
        [self setAssociatedObject:storedHeight forKey:key];
    }
    return [storedHeight floatValue];
}

- (CGFloat)heightWithFont:(UIFont *)font width:(CGFloat)width {
    return ceilf([self boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size.height);
}

- (CGFloat)widthWithFont:(UIFont *)font size:(CGSize)size {
    return ceilf([self boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size.width);
}

- (NSString *)stringByCapitalizingFirstCharacter {
    if (self.length == 0) return self;
    NSRange range = NSMakeRange(0,1);
    return [self stringByReplacingCharactersInRange:range withString:[[self substringWithRange:range] capitalizedString]];
}

- (NSDictionary *)URLQueryParameters {
    NSString *query = [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    for (NSString *pair in [query componentsSeparatedByString:@"&"]) {
        NSArray *components = [pair componentsSeparatedByString:@"="];
        if([components count] < 2) continue;
        parameters[components[0]] = components[1];
    }
    return [parameters copy];
}

@end

@implementation NSNumber (Additions)

- (BOOL)isEqualToInteger:(NSInteger)integer {
    NSInteger i;
    [self getValue:&i];
    return (i == integer);
}

@end
