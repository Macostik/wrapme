//
//  WLCryptographer.h
//  WrapLive
//
//  Created by Sergey Maximenko on 08.01.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLCryptographer : NSObject

+ (NSData*)encryptData:(NSData*)data;

+ (NSData*)decryptData:(NSData*)data;

+ (NSData*)encryptString:(NSString*)string;

+ (NSString*)decryptString:(NSData*)data;

@end
