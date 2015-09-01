//
//  WLTelephony.h
//  moji
//
//  Created by Ravenpod on 11/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLTelephony : NSObject

+ (NSString*)countryCode;

+ (BOOL)isCallingNow;

+ (BOOL)hasPhoneNumber;

@end
