//
//  WLCryptographer.m
//  WrapLive
//
//  Created by Sergey Maximenko on 08.01.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCryptographer.h"
#import <CommonCrypto/CommonCrypto.h>

const char *WLCryptographerKey = "PgHf7Jfk90Jhfg0d";

@implementation WLCryptographer

CCCryptorStatus PGEncrypt(const void *dataIn, size_t dataInLength, void *dataOut, size_t dataOutAvailable, size_t *dataOutMoved) {
	return CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, WLCryptographerKey, kCCKeySizeAES128, NULL, dataIn, dataInLength, dataOut, dataOutAvailable, dataOutMoved);
}

CCCryptorStatus PGDecrypt(const void *dataIn, size_t dataInLength, void *dataOut, size_t dataOutAvailable, size_t *dataOutMoved) {
	return CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, WLCryptographerKey, kCCKeySizeAES128, NULL, dataIn, dataInLength, dataOut, dataOutAvailable, dataOutMoved);
}

+ (NSData *)encrypt:(NSString *)string {
	char buffer[500];
	bzero(buffer, sizeof(buffer));
	size_t n = 0;
	CCCryptorStatus r = PGEncrypt([string UTF8String], string.length, buffer, sizeof(buffer), &n);
	return (r == kCCSuccess) ? [NSData dataWithBytes:buffer length:n] : nil;
}

+ (NSString *)decrypt:(NSData *)data {
	char buffer[500];
	bzero(buffer, sizeof(buffer));
	CCCryptorStatus r = PGDecrypt([data bytes], [data length], buffer, sizeof(buffer), NULL);
	return (r == kCCSuccess) ? [NSString stringWithUTF8String:buffer] : nil;
}

@end
