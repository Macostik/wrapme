//
//  WLEntryFactory.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/10/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryFactory.h"
#import "WLEntry.h"

@implementation WLEntryFactory

+ (NSMutableDictionary*)entries {
    static NSMutableDictionary* entries = nil;
    if (!entries) {
        entries = [NSMutableDictionary dictionary];
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                entries = nil;
            }];
        });
    }
    return entries;
}

+ (NSHashTable*)entries:(WLEntry *)entry {
    NSString* className = NSStringFromClass([entry class]);
    NSHashTable* entries = [[self entries] objectForKey:className];
    if (!entries) {
        entries = [NSHashTable weakObjectsHashTable];
        [[self entries] setObject:entries forKey:className];
    }
    return entries;
}

+ (WLEntry *)entry:(WLEntry *)entry {
    NSHashTable* entries = [self entries:entry];
    for (WLEntry* _entry in entries) {
        if ([_entry isEqualToEntry:entry]) {
            [_entry updateWithObject:entry broadcast:NO];
            return _entry;
        }
    }
    [entries addObject:entry];
    return entry;
}

@end
