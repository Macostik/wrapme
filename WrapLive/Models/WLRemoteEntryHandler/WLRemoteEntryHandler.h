//
//  WLRemoteObjectHandler.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLEntry;
@class WLNotification;

@interface WLRemoteEntryHandler : NSObject

@property (assign, nonatomic) BOOL isLoaded;

+ (instancetype)sharedHandler;

- (void)presentEntry:(WLEntry*)entry;

- (void)presentEntry:(WLEntry*)entry animated:(BOOL)animated;

@end

@interface WLRemoteEntryHandler (WLNotification)

- (void)presentEntryFromNotification:(WLNotification*)notification;

@end

@interface WLRemoteEntryHandler (NSURL)

- (void)presentEntryFromURL:(NSURL*)url;

@end

@interface WLRemoteEntryHandler (WatchKit)

- (void)presentEntryFromWatchKitEvent:(NSDictionary*)event;

@end
