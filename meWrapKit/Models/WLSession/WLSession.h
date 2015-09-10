//
//  WLSession.h
//  meWrap
//
//  Created by Ravenpod on 21.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLAuthorization;

#define WLSession [NSUserDefaults standardUserDefaults]

@interface NSUserDefaults (WLSessionData)

@property WLAuthorization *authorization;

@property NSHTTPCookie *authorizationCookie;

@property (readonly) NSString *UDID;

@property NSData *deviceToken;

@property NSDate *confirmationDate;

@property NSString *appVersion;

@property NSUInteger numberOfLaunches;

@property NSTimeInterval serverTimeDifference;

@property NSNumber *cameraDefaultPosition;

@property NSNumber *cameraDefaultFlashMode;

@property NSMutableDictionary *shownHints;

@property NSDate *historyDate;

@property NSOrderedSet *handledNotifications;

@property NSArray *recentEmojis;

@property NSString *imageURI;

@property NSString *avatarURI;

@property NSInteger pageSize;

- (void)clear;

@end
