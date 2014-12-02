//
//  WLCryptographer.h
//  WrapLive
//
//  Created by Sergey Maximenko on 08.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLCryptographer : NSObject

+ (NSData*)encrypt:(NSString*)string;
+ (NSString*)decrypt:(NSData*)data;

@end
