//
//  WLEditSession.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditSession.h"

@interface WLEditSession ()

@end

@implementation WLEditSession

- (id)initWithEntry:(WLEntry *)entry {
    self = [super init];
    if (self) {
        self.original = [NSMutableDictionary dictionary];
        self.changed = [NSMutableDictionary dictionary];
        self.entry = entry;
        [self setup:self.original entry:entry];
        [self setup:self.changed entry:entry];
    }
    return self;
}

- (void)setup:(NSMutableDictionary *)dictionary entry:(WLEntry *)entry {
    
}

- (void)apply:(NSMutableDictionary *)dictionary entry:(WLEntry *)entry {
    
}

- (void)apply:(WLEntry *)entry {
    [self apply:self.changed entry:entry];
}

- (void)reset:(WLEntry *)entry {
    [self apply:self.original entry:entry];
}

- (void)clean {
    [self setup:self.changed entry:self.entry];
}

- (BOOL)hasChanges {
    return NO;
}

@end
