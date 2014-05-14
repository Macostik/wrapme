//
//  WLSession.h
//  WrapLive
//
//  Created by Sergey Maximenko on 21.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLUser;

@interface WLSession : NSObject

/**
 *  Get current authenticated user.
 *
 *  @return WLUser object
 */
+ (WLUser*)user;

/**
 *  Set current authenticated user.
 *
 *  @param user WLUser object
 */
+ (void)setUser:(WLUser*)user;

/**
 *  Get UDID for current device.
 *
 *  @return string object with UDID
 */
+ (NSString*)UDID;

+ (NSString *)birthdate;

+ (void)setBirthdate:(NSString *)birthdate;

/**
 *  Get password for current authenticated user.
 *
 *  @return string object with password
 */
+ (NSString*)password;

/**
 *  Set password for current authenticated user.
 *
 *  @param password string object with password
 */
+ (void)setPassword:(NSString*)password;

+ (BOOL)activated;

+ (void)clear;

+ (NSData*)deviceToken;

+ (void)setDeviceToken:(NSData*)deviceToken;

@end
