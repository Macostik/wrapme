//
//  NSString+MD5.m
//  WrapLive
//
//  Created by Sergey Maximenko on 28.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonCrypto.h>
#import <objc/runtime.h>

@implementation NSString (MD5)

- (NSString*)MD5 {
	NSString* MD5 = objc_getAssociatedObject(self, "MD5");
	if (!MD5) {
		const char *ptr = [self UTF8String];
		unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
		CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);
		NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
		for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
			[output appendFormat:@"%02x",md5Buffer[i]];
		MD5 = output;
		objc_setAssociatedObject(self, "MD5", MD5, OBJC_ASSOCIATION_RETAIN);
	}
	return MD5;
}

@end
