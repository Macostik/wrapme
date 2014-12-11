//
//  WLRemoteObjectHandler.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLRemoteObjectHandler.h"
#import "WLEntry.h"
#import "WLNavigation.h"
#import "WLNotification.h"
#import "NSError+WLAPIManager.h"
#import "WLNotificationCenter.h"
#import "WLAPIManager.h"
#import "WLHomeViewController.h"
#import "WLWelcomeViewController.h"

@interface WLRemoteObjectHandler ()

@property (strong, nonatomic) WLEntry* pendingRemoteObject;

@end

@implementation WLRemoteObjectHandler

+ (instancetype)sharedObject {
    static WLRemoteObjectHandler *_sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedObject = [WLRemoteObjectHandler new];
    });
    
    return _sharedObject;
}

- (void)handleRemoteObject:(WLEntry *)entry {
    self.pendingRemoteObject = entry;
    if ([entry valid] && _isLoaded) {
        [entry presentViewControllerWithoutLostData];
        self.pendingRemoteObject = nil;
    }
}

- (void)setIsLoaded:(BOOL)isLoaded {
    _isLoaded = isLoaded;
    if (_isLoaded && self.pendingRemoteObject != nil) {
        [self handleRemoteObject:self.pendingRemoteObject];
    }
}

@end

@implementation WLNotification (WLRemoteObjectHandler)

- (void)handleRemoteObject {
    if (self.event != WLEventDelete) {
        [[WLRemoteObjectHandler sharedObject] handleRemoteObject:self.targetEntry];
    }
}

@end

@implementation NSURL (WLRemoteObjectHandler)

- (void)handleRemoteObject {
    if ([[self.path lastPathComponent] isEqualToString:WLCandyKey]) {
        NSMutableString *urlString = [[self query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding].mutableCopy;
        NSRange range = [urlString rangeOfString:@"uid="];
        NSString *entryID = [urlString substringFromIndex:range.location + range.length];
        [[WLRemoteObjectHandler sharedObject] handleRemoteObject:[WLCandy entry:entryID]];;
    }
}

@end