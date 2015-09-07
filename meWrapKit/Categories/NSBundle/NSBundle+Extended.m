//
//  NSPropertyListSerialization+Shorthand.m
//  meWrap
//
//  Created by Ravenpod on 22.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSBundle+Extended.h"

@implementation NSBundle (Extended)

- (NSString*)plist:(NSString *)name {
	return [self pathForResource:name ofType:@"plist"];
}

- (NSString *)displayName {
    return [self objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}

- (NSString *)buildVersion {
    return [self objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)buildNumber {
    return [self objectForInfoDictionaryKey:(id)kCFBundleVersionKey];
}

- (NSString *)groupIdentifier {
    return [self objectForInfoDictionaryKey:@"AppGroupIdentifier"];
}

- (NSString *)URLScheme {
    return [self objectForInfoDictionaryKey:@"URLScheme"];
}

@end

@implementation NSArray (NSBundleExtended)

+ (instancetype)plist:(NSString *)name {
	return [self arrayWithContentsOfFile:[[NSBundle mainBundle] plist:name]];
}

@end

@implementation NSDictionary (NSBundleExtended)

+ (instancetype)plist:(NSString *)name {
	return [self dictionaryWithContentsOfFile:[[NSBundle mainBundle] plist:name]];
}

@end
