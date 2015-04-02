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

NSData *sha1(NSData *bytes) {
    NSMutableData *_md = [NSMutableData dataWithLength:16];
    unsigned char *result = [_md mutableBytes];
    if (result != CC_SHA1([bytes bytes], (CC_LONG)[bytes length], result)) {
        @throw [NSException exceptionWithName:@"SHA1Exception"
                                       reason:@"Unknown"
                                     userInfo:nil];
    }
    return _md;
}

NSData *sha256(NSData *bytes) {
    NSMutableData *_md = [NSMutableData dataWithLength:32];
    unsigned char *result = [_md mutableBytes];
    if (result != CC_SHA256([bytes bytes], (CC_LONG)[bytes length], result)) {
        @throw [NSException exceptionWithName:@"SHA256Exception"
                                       reason:@"Unknown"
                                     userInfo:nil];
    }
    return _md;
}

NSData *cipher(NSData *key,
               NSData *value,
               NSData *iv,
               CCOperation operation,
               CCOptions options,
               NSMutableData *output) {
    
    // NSLog(@"\nk=%@\nv=%@\ni=%@",key,value,iv);
    // SHA256 the key unless it's already 256 bits.
    if (kCCKeySizeAES256 != [key length]) {
        key = sha256(key);
    }
    
    int len = (int)[value length];
    int capacity = (int)(len / kCCBlockSizeAES128 + 1) * kCCBlockSizeAES128;
    NSMutableData *data;
    if (nil == output) {
        data = [NSMutableData dataWithLength:capacity];
    } else {
        data = output;
        if ([data length] < capacity) {
            [data setLength:capacity];
        }
    }
    
    /*
     NSLog(@"\nlen = %d, capacity = %d\n%@[%d]\n%@[%d]",
     len, capacity,
     key,[key length],
     value, [value length]
     );
     //*/
    
    // SHA1 the IV if provided.
    if (iv && kCCBlockSizeAES128 != [iv length]) {
        iv = sha1(iv);
    } else {
        iv = [NSMutableData dataWithLength:kCCBlockSizeAES128];
    }
    
    const void *_iv = [iv bytes];
    
    size_t dataOutMoved;
    CCCryptorStatus ccStatus = CCCrypt(operation,
                                       kCCAlgorithmAES128,
                                       options,
                                       (const char*) [key bytes],
                                       [key length],
                                       _iv,
                                       (const void *) [value bytes],
                                       [value length],
                                       (void *)[data mutableBytes],
                                       capacity,
                                       &dataOutMoved
                                       );
    
    if (dataOutMoved < [data length]) {
        [data setLength:dataOutMoved];
    }
    
    switch (ccStatus) {
        case kCCSuccess:
            return data;
            break;
            
        case kCCParamError:
            @throw [NSException exceptionWithName:@"IllegalParameterValueException"
                                           reason:@"Illegal parameter value."
                                         userInfo:nil];
            break;
        case kCCBufferTooSmall:
            @throw [NSException exceptionWithName:@"InsufficentBufferException"
                                           reason:@"Insufficent buffer provided for specified operation."
                                         userInfo:nil];
            break;
        case kCCMemoryFailure:
            @throw [NSException exceptionWithName:@"MemoryAllocationFailure."
                                           reason:@"Memory allocation failure."
                                         userInfo:nil];
            break;
        case kCCAlignmentError:
            @throw [NSException exceptionWithName:@"InputAlignmentException"
                                           reason:@"Input size was not aligned properly. "
                                         userInfo:nil];
            break;
        case kCCDecodeError:
            @throw [NSException exceptionWithName:@"DecryptionException."
                                           reason:@"Input data did not decode or decrypt properly."
                                         userInfo:nil];
            break;
        case kCCUnimplemented:
            @throw [NSException exceptionWithName:@"FunctionNotImplementedException"
                                           reason:@"Function not implemented for the current algorithm."
                                         userInfo:nil];
            break;
    }
    return nil;
}

@implementation WLCryptographer

CCCryptorStatus PGEncrypt(const void *dataIn, size_t dataInLength, void *dataOut, size_t dataOutAvailable, size_t *dataOutMoved) {
	return CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, WLCryptographerKey, kCCKeySizeAES128, NULL, dataIn, dataInLength, dataOut, dataOutAvailable, dataOutMoved);
}

CCCryptorStatus PGDecrypt(const void *dataIn, size_t dataInLength, void *dataOut, size_t dataOutAvailable, size_t *dataOutMoved) {
	return CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, WLCryptographerKey, kCCKeySizeAES128, NULL, dataIn, dataInLength, dataOut, dataOutAvailable, dataOutMoved);
}

+ (NSData*)encryptData:(NSData*)data {
    return cipher([NSData dataWithBytes:WLCryptographerKey length:strlen(WLCryptographerKey)], data, nil, kCCEncrypt, kCCOptionPKCS7Padding, nil);
//    int capacity = (int)(data.length / kCCBlockSizeAES128 + 1) * kCCBlockSizeAES128;
//    char buffer[capacity];
//    bzero(buffer, sizeof(buffer));
//    size_t n = 0;
//    CCCryptorStatus r = PGEncrypt(data.bytes, data.length, buffer, capacity, &n);
//    return (r == kCCSuccess) ? [NSData dataWithBytes:buffer length:n] : nil;
}

+ (NSData*)decryptData:(NSData*)data {
    return cipher([NSData dataWithBytes:WLCryptographerKey length:strlen(WLCryptographerKey)], data, nil, kCCDecrypt, kCCOptionPKCS7Padding, nil);
//    char buffer[500];
//    bzero(buffer, sizeof(buffer));
//    CCCryptorStatus r = PGDecrypt([data bytes], [data length], buffer, sizeof(buffer), NULL);
//    return (r == kCCSuccess) ? [NSData dataWithBytes:buffer length:500] : nil;
}

+ (NSData*)encryptString:(NSString*)string {
    return [self encryptData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSString*)decryptString:(NSData*)data {
    return [[NSString alloc] initWithData:[self decryptData:data] encoding:NSUTF8StringEncoding];
}

@end
