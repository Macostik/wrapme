//
//  NSDictionary+Extended.m
//  Riot
//
//  Created by Sergey Maximenko on 21.08.12.
//
//

#import "NSDictionary+Extended.h"
#import "NSDate+Formatting.h"
#import "NSArray+Additions.h"

@implementation NSDictionary (Extended)

+ (id)dictionaryWithContentsOfPlist:(NSString *)plistName {
    NSString* path = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    return [self dictionaryWithContentsOfFile:path];
}

- (id)tryObjectForKey:(id)key {
    id object = [self objectForKey:key];
    
    if (object == nil || [object isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    return object;
}

- (id)objectForPossibleKeys:(id)key, ... {
    id object = nil;
	
	va_list args;
    va_start(args, key);
    
    for (; key != nil; key = va_arg(args, id)) {
		object = [self tryObjectForKey:key];
        if (object) break;
	}
    
    va_end(args);
	return object;
}

- (id)objectOfClass:(Class)class forKey:(id)key {
    id object = [self objectForKey:key];
    return [object isKindOfClass:class] ? object : nil;
}

- (NSString *)stringForKey:(id)key {
    id object = [self objectOfClass:[NSString class] forKey:key];
    
    if (!object) {
        object = [[self objectOfClass:[NSNumber class] forKey:key] stringValue];
    }
    
    return object ?:@"";
}

- (NSURL *)urlForKey:(id)key {
    NSString* urlString = [self stringForKey:key];
    if (urlString && urlString.length > 0) {
        return [NSURL URLWithString:urlString];
    }
    return nil;
}

- (NSNumber*)numberForKey:(id)key {
    id object = [self objectOfClass:[NSNumber class] forKey:key];
    if (!object) {
        object = @([[self objectOfClass:[NSString class] forKey:key] floatValue]);
    }
    return object;
}

- (NSDate *)dateForKey:(id)key {
    return [[self stringForKey:key] date];
}

- (NSDate *)dateForKey:(id)key withFormat:(NSString *)dateFormat {
    return [[self stringForKey:key] dateWithFormat:dateFormat];
}

- (NSArray *)arrayForKey:(id)key {
    return [self objectOfClass:[NSArray class] forKey:key];
}

- (NSDictionary *)dictionaryForKey:(id)key {
    return [self objectOfClass:[NSDictionary class] forKey:key];
}

- (CGFloat)floatForKey:(id)key {
    return [[self tryObjectForKey:key] floatValue];
}

- (BOOL)boolForKey:(id)key {
    return [[self tryObjectForKey:key] boolValue];
}

- (NSInteger)integerForKey:(id)key {
    return [[self tryObjectForKey:key] integerValue];
}

- (NSString *)queryString {
    NSMutableString* string = [NSMutableString string];
    
    for (NSString* key in self) {
        
        if (string.length > 0) {
            [string appendString:@"&"];
        }
        
        [string appendFormat:@"%@=%@",[key stringByReplacingOccurrencesOfString:@" " withString:@"%20"],[[self objectForKey:key] stringByReplacingOccurrencesOfString:@" " withString:@"%20"]];
    }
    
    return string;
}

- (NSDictionary *)unnulable {
    const NSMutableDictionary *replaced = [self mutableCopy];
    const id nul = [NSNull null];
    const NSString *blank = @"";
    
    for (NSString *key in self) {
        id object = [self objectForKey:key];
        if (object == nul) [replaced setObject:blank forKey:key];
        else if ([object isKindOfClass:[NSDictionary class]]) [replaced setObject:[object unnulable] forKey:key];
        else if ([object isKindOfClass:[NSArray class]]) [replaced setObject:[object unnulable] forKey:key];
    }
    return [NSDictionary dictionaryWithDictionary:[replaced copy]];
}

- (id)merge:(NSDictionary *)dictionary {
	NSMutableDictionary* _dictionary = [self mutableCopy];
	[_dictionary addEntriesFromDictionary:dictionary];
	return [_dictionary copy];
}

@end

@implementation NSMutableDictionary (Extended)

- (BOOL)trySetObject:(id)object forKey:(id)key {
    if (object) {
        [self setObject:object forKey:key];
        return YES;
    } else {
        return NO;
    }
}

- (id)merge:(NSDictionary *)dictionary {
	[self addEntriesFromDictionary:dictionary];
	return self;
}

@end
