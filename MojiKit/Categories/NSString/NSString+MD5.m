//
//  NSString+MD5.m
//  moji
//
//  Created by Ravenpod on 28.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonCrypto.h>
#import <objc/runtime.h>
#import "NSObject+AssociatedObjects.h"

@implementation NSString (MD5)

- (NSString*)MD5 {
	NSString* MD5 = [self associatedObjectForKey:"MD5"];
	if (!MD5) {
		const char *ptr = [self UTF8String];
		unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
		CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);
		NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
		for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
			[output appendFormat:@"%02x",md5Buffer[i]];
		MD5 = output;
		[self setAssociatedObject:MD5 forKey:"MD5"];
	}
	return MD5;
}

@end
