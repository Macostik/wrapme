//
//  WLEditSession.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditSession.h"
#import "WLTempEntry.h"

@interface WLEditSession ()

- (void)setupSessionWithEntry:(WLEntry *)entry;

@end

@implementation WLEditSession

- (id)initWithEntry:(WLEntry *)entry {
    self = [super init];
    if (self) {
        [self setupSessionWithEntry:(WLEntry *)entry];
    }
    return self;
}

- (void)setupSessionWithEntry:(WLEntry *)entry {
    
}

- (BOOL)hasChanges {
    return NO;
}

- (void)applyChanges:(WLEntry *)entry {
    [self applyTempEntry:self.changedEntry intoEntry:entry];
}

- (void)resetChanges:(WLEntry *)entry {
    [self applyTempEntry:self.originalEntry intoEntry:entry];
}

- (void)applyTempEntry:(WLTempEntry *)tempEntry intoEntry:(WLEntry *)entry {
    
}

@end
