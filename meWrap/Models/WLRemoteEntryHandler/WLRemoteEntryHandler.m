//
//  WLRemoteObjectHandler.m
//  meWrap
//
//  Created by Yura Granchenko on 12/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLRemoteEntryHandler.h"
#import "WLNotificationEntryPresenter.h"
#import "WLNotification.h"

@interface WLRemoteEntryHandler ()

@property (strong, nonatomic) NSDictionary *entryReference;

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

- (BOOL)presentEntry:(Entry *)entry {
    return [self presentEntry:entry animated:NO];
}

- (BOOL)presentEntry:(Entry *)entry animated:(BOOL)animated {
    if (_isLoaded) {
        if (entry.valid) {
            [WLNotificationEntryPresenter presentEntryRequestingAuthorization:entry animated:animated];
            self.entryReference = nil;
        }
    }
    return _isLoaded;
}

- (void)setIsLoaded:(BOOL)isLoaded {
    _isLoaded = isLoaded;
    if (_isLoaded) {
        Entry *entry = [Entry deserializeReference:self.entryReference];
        if ([entry valid]) {
            [self presentEntry:entry];
        } else {
            if (self.failureBlock) self.failureBlock(WLError(@"no_presenting_data".ls));
        }
        self.failureBlock = nil;
    }
}

@end

@implementation WLRemoteEntryHandler (WLNotification)

- (void)presentEntryFromNotification:(WLNotification*)notification failure:(WLFailureBlock)failure {
    if (notification.event != WLEventDelete) {
        if ([notification.descriptor entryExists]) {
            if (![self presentEntry:notification.entry]) {
                self.entryReference = [notification.entry serializeReference];
                self.failureBlock = failure;
            }
        } else {
            if (failure) failure(WLError(@"no_presenting_data".ls));
        }
    } else {
        if (failure) failure(WLError(@"Cannot handle delete event"));
    }
}

@end

@implementation WLRemoteEntryHandler (NSURL)

- (void)presentEntryFromURL:(NSURL*)url failure:(WLFailureBlock)failure {
    
    NSDictionary *parameters = [[url query] URLQuery];
    NSString *identifier = parameters[WLUIDKey];
    if (identifier.nonempty) {
        self.entryReference = parameters;
        Entry *entry = [Entry deserializeReference:self.entryReference];
        if (entry) {
            [self presentEntry:entry];
        } else {
            if (failure) failure(WLError(@"no_presenting_data".ls));
        }
    } else {
        if (failure) failure(WLError(@"Invalid data"));
    }
}

@end