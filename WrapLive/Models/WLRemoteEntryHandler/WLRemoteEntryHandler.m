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

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *key;

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

- (void)presentEntry:(WLEntry *)entry {
    [self presentEntry:entry animated:NO];
}

- (void)presentEntry:(WLEntry *)entry animated:(BOOL)animated {
    if (_isLoaded) {
        if (entry.valid) {
            [WLNotificationEntryPresenter presentEntryRequestingAuthorization:entry animated:animated];
            self.key = nil;
            self.identifier = nil;
        }
    }
}

- (void)setIsLoaded:(BOOL)isLoaded {
    _isLoaded = isLoaded;
    if (_isLoaded && [self.identifier nonempty]) {
        id entry = [self entryByKey:self.key withIdentifier:self.identifier];
        if ([entry valid]) {
            [self presentEntry:entry];
        }
    }
}

- (WLEntry *)entryByKey:(NSString *)key withIdentifier:(NSString *)identifier {
    
    Class entryClass = nil;
    
    if ([key isEqualToString:WLCandyKey]) {
       entryClass = [WLCandy class];
    } else if ([key isEqualToString:WLCommentKey])  {
    entryClass = [WLComment class];
    } else  if ([key isEqualToString:WLMessageKey])  {
        entryClass = [WLMessage class];
    } else {
        return nil;
    }
    
    if (entryClass && [[WLEntryManager manager] entryExists:entryClass identifier:identifier]) {
        return [entryClass entry:identifier];
    }
    return nil;
}

@end

@implementation WLRemoteEntryHandler (WLNotification)

- (void)presentEntryFromNotification:(WLEntryNotification*)notification {
    if (notification.event != WLEventDelete) {
        switch (notification.type) {
            case WLNotificationMessageAdd: {
                self.key = WLMessageKey;
                self.identifier = notification.targetEntry.identifier;
            }
                break;
            case WLNotificationCandyAdd: {
                self.key = WLCandyKey;
                self.identifier = notification.targetEntry.identifier;
            }
                break;
            default:
                break;
        }
        if (notification.type == WLNotificationMessageAdd) {
           
        }
        [self presentEntry:notification.targetEntry];
    }
}

@end

@implementation WLRemoteEntryHandler (NSURL)

- (void)presentEntryFromURL:(NSURL*)url failure:(WLFailureBlock)failure {
    NSDictionary *parameters = [[url query] URLQueryParameters];
    NSString *identifier = parameters[WLUIDKey];
    if (identifier.nonempty) {
        NSString *key = [url path].lastPathComponent;
        self.key = key;
        self.identifier = identifier;
        WLEntry *entry = [self entryByKey:key withIdentifier:identifier];
        if (entry) {
            [self presentEntry:entry];
        } else {
            if (failure) failure(WLError(@"This item isn't available"));
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