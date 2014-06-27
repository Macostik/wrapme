//
//  WLEditSession.h
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLEntry;
@class WLTempEntry;

@interface WLEditSession : NSObject

@property (strong, nonatomic) WLTempEntry *originalEntry;
@property (strong, nonatomic) WLTempEntry *changedEntry;

- (instancetype)initWithEntry:(WLEntry *)entry;
- (BOOL)hasChanges;
- (void)applyChanges:(WLEntry *)entry;
- (void)resetChanges:(WLEntry *)entry;

@end
