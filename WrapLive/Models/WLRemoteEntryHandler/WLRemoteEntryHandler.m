//
//  WLRemoteObjectHandler.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLRemoteEntryHandler.h"
#import "WLEntry.h"
#import "WLNavigationHelper.h"
#import "NSString+Additions.h"
#import "WLNotificationEntryPresenter.h"
#import "WLEntryNotification.h"

@interface WLRemoteEntryHandler ()

@property (strong, nonatomic) NSString *entryIdentifier;

@property (strong, nonatomic) Class entryClass;

@property (strong, nonatomic) WLFailureBlock failureBlock;

@end

@implementation WLRemoteEntryHandler

+ (instancetype)sharedHandler {
    static WLRemoteEntryHandler *_sharedHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedHandler = [WLRemoteEntryHandler new];
    });
    return _sharedHandler;
}

- (BOOL)presentEntry:(WLEntry *)entry {
    return [self presentEntry:entry animated:NO];
}

- (BOOL)presentEntry:(WLEntry *)entry animated:(BOOL)animated {
    if (_isLoaded) {
        if (entry.valid) {
            [WLNotificationEntryPresenter presentEntryRequestingAuthorization:entry animated:animated];
            self.entryIdentifier = nil;
            self.entryClass = nil;
        }
    }
    return _isLoaded;
}

- (void)setIsLoaded:(BOOL)isLoaded {
    _isLoaded = isLoaded;
    if (_isLoaded) {
        id entry = [self entryByClass];
        if ([entry valid]) {
            [self presentEntry:entry];
        } else {
            if (self.failureBlock) self.failureBlock(WLError(WLLS(@"no_presenting_data")));
        }
        self.failureBlock = nil;
    }
}

- (WLEntry *)entryByClass {
    if (self.entryClass && [self.entryClass entryExists:self.entryIdentifier]) {
        return [self.entryClass entry:self.entryIdentifier];
    }
    
    return nil;
}

@end

@implementation WLRemoteEntryHandler (WLNotification)

- (void)presentEntryFromNotification:(WLEntryNotification*)notification failure:(WLFailureBlock)failure {
    if (notification.event != WLEventDelete) {
        if ([notification.entryClass entryExists:notification.entryIdentifier]) {
            if (![self presentEntry:notification.targetEntry]) {
                self.entryClass = notification.entryClass;
                self.entryIdentifier = notification.entryIdentifier;
                self.failureBlock = failure;
            }
        } else {
            if (failure) failure(WLError(WLLS(@"no_presenting_data")));
        }
    } else {
        if (failure) failure(WLError(@"Cannot handle delete event"));
    }
}

@end

@implementation WLRemoteEntryHandler (NSURL)

- (void)presentEntryFromURL:(NSURL*)url failure:(WLFailureBlock)failure {
    NSDictionary *parameters = [[url query] URLQueryParameters];
    NSString *identifier = parameters[WLUIDKey];
    if (identifier.nonempty) {
        NSString *key = [url path].lastPathComponent;
        self.entryClass = [WLEntry entryClassByName:key];
        self.entryIdentifier = identifier;
        WLEntry *entry = [self entryByClass];
        if (entry) {
            [self presentEntry:entry];
        } else {
            if (failure) failure(WLError(WLLS(@"no_presenting_data")));
        }
    } else {
        if (failure) failure(WLError(@"Invalid data"));
    }
}

@end

@implementation WLRemoteEntryHandler (WatchKit)

- (void)presentEntryFromWatchKitEvent:(NSDictionary*)event {
    NSString *identifier = event[@"identifier"];
    NSString *entity = event[@"entity"];
    if (identifier.nonempty && entity.nonempty) {
        WLEntry *entry = [NSClassFromString(entity) entry:identifier];
        if (entry) {
            [self presentEntry:entry animated:NO];
        }
    }
}

@end