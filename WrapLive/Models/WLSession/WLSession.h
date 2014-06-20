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

@end
