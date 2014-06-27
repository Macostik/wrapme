//
//  WLTempEntry.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTempEntry.h"

@implementation WLTempEntry

- (instancetype)initWithEntry:(WLEntry *)entry {
    self = [super init];
    if (self) {
    }
    [self setupEntry:entry];
    return self;
}

- (void)setupEntry:(WLEntry *)entry {
    
}

@end
