//
//  NSPropertyListSerialization+Shorthand.m
//  WrapLive
//
//  Created by Sergey Maximenko on 22.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSPropertyListSerialization+Shorthand.h"

@implementation NSPropertyListSerialization (Shorthand)

+ (instancetype)resourcePropertyListNamed:(NSString *)name {
	NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	return [self propertyListFromData:[NSData dataWithContentsOfFile:path] mutabilityOption:NSPropertyListImmutable format:&format errorDescription:NULL];
}

+ (instancetype)mutableResourcePropertyListNamed:(NSString *)name {
	NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	return [self propertyListFromData:[NSData dataWithContentsOfFile:path] mutabilityOption:NSPropertyListMutableContainers format:&format errorDescription:NULL];
}

@end

@implementation NSArray (NSPropertyListSerializationShorthand)

+ (instancetype)resourcePropertyListNamed:(NSString *)name {
	NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
	return [self arrayWithContentsOfFile:path];
}

+ (instancetype)mutableResourcePropertyListNamed:(NSString *)name {
	NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
	return [[self arrayWithContentsOfFile:path] mutableCopy];
}

@end

@implementation NSDictionary (NSPropertyListSerializationShorthand)

+ (instancetype)resourcePropertyListNamed:(NSString *)name {
	NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
	return [self dictionaryWithContentsOfFile:path];
}

+ (instancetype)mutableResourcePropertyListNamed:(NSString *)name {
	NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
	return [[self dictionaryWithContentsOfFile:path] mutableCopy];
}

@end
