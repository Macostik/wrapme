//
//  WLRemoteObjectHandler.h
//  meWrap
//
//  Created by Yura Granchenko on 12/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLNotification;

@interface WLRemoteEntryHandler : NSObject

@property (assign, nonatomic) BOOL isLoaded;

+ (instancetype)sharedHandler;

- (BOOL)presentEntry:(Entry *)entry;

- (BOOL)presentEntry:(Entry *)entry animated:(BOOL)animated;

@end

@interface WLRemoteEntryHandler (WLNotification)

- (void)presentEntryFromNotification:(WLNotification*)notification failure:(WLFailureBlock)failure;

@end

@interface WLRemoteEntryHandler (NSURL)

- (void)presentEntryFromURL:(NSURL*)url failure:(WLFailureBlock)failure;

@end
