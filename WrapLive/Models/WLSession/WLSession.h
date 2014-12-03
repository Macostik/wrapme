//
//  WLSession.h
//  WrapLive
//
//  Created by Sergey Maximenko on 21.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLUser;
@class WLAuthorization;

static NSUserDefaults* WLUserDefaults = nil;

@interface WLSession : NSObject

/**
 *  Get current authorization.
 *
 *  @return WLAuthorization object
 */
+ (WLAuthorization*)authorization;

/**
 *  Set current authorization.
 *
 *  @param authorization WLAuthorization object
 */
+ (void)setAuthorization:(WLAuthorization*)authorization;

/**
 *  Get UDID for current device.
 *
 *  @return string object with UDID
 */
+ (NSString*)UDID;

+ (void)clear;

+ (NSData*)deviceToken;

+ (void)setDeviceToken:(NSData*)deviceToken;

+ (NSDate *)confirmationDate;

+ (void)setConfirmationDate:(NSDate *)confirmationConditions;

+ (void)setObject:(id)o key:(NSString*)k;

+ (void)setDouble:(double)d key:(NSString*)k;

+ (void)setInteger:(NSInteger)i key:(NSString*)k;

+ (id)object:(NSString*)k;

+ (double)wl_double:(NSString*)k;

+ (NSInteger)integer:(NSString*)k;

+ (void)synchronize;

+ (NSString*)appVersion;

+ (void)setAppVersion:(NSString*)version;

+ (void)setCurrentAppVersion;

@end
