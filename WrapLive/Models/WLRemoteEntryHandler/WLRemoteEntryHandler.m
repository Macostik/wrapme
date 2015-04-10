//
//  WLRemoteObjectHandler.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLRemoteEntryHandler.h"
#import "WLEntry.h"
#import "WLNavigation.h"
#import "NSString+Additions.h"

@interface WLRemoteEntryHandler ()

@property (weak, nonatomic) WLEntry* entry;

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
        if (entry.valid) [entry presentViewControllerWithoutLostData];
    } else {
        self.entry = entry;
    }
}

- (void)setIsLoaded:(BOOL)isLoaded {
    _isLoaded = isLoaded;
    if (_isLoaded && self.entry != nil) {
        [self presentEntry:self.entry];
        self.entry = nil;
    }
}

@end

@implementation WLRemoteEntryHandler (WLNotification)

- (void)presentEntryFromNotification:(WLEntryNotification*)notification {
    if (notification.event != WLEventDelete) {
        [self presentEntry:notification.targetEntry];
    }
}

@end

@implementation WLRemoteEntryHandler (NSURL)

- (void)presentEntryFromURL:(NSURL*)url {
    if ([[url.path lastPathComponent] isEqualToString:WLCandyKey]) {
        NSDictionary *parameters = [[url query] URLQueryParameters];
        NSString *identifier = parameters[WLUIDKey];
        if (identifier.nonempty) {
            [self presentEntry:[WLCandy entry:identifier]];
        }
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
            [self presentEntry:entry animated:YES];
        }
    }
}

@end