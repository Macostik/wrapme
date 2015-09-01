//
//  WLCryptographer.m
//  moji
//
//  Created by Ravenpod on 08.01.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCryptographer.h"
#import <CommonCrypto/CommonCrypto.h>
#import "NSData+CommonCrypto.h"

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

static const NSString *WLCryptographerKey = @"PgHf7Jfk90Jhfg0d";

@implementation WLCryptographer

+ (NSData*)encryptData:(NSData*)data {
    // sha256 is used here for backward compatibility purpose
    return [data dataEncryptedUsingAlgorithm:kCCAlgorithmAES128 key:sha256([WLCryptographerKey dataUsingEncoding:NSUTF8StringEncoding]) options:kCCOptionPKCS7Padding error:NULL];
}

+ (NSData*)decryptData:(NSData*)data {
    // sha256 is used here for backward compatibility purpose
    return [data decryptedDataUsingAlgorithm:kCCAlgorithmAES128 key:sha256([WLCryptographerKey dataUsingEncoding:NSUTF8StringEncoding]) options:kCCOptionPKCS7Padding error:NULL];
}

+ (NSData*)encryptString:(NSString*)string {
    return [self encryptData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSString*)decryptString:(NSData*)data {
    return [[NSString alloc] initWithData:[self decryptData:data] encoding:NSUTF8StringEncoding];
}

@end
