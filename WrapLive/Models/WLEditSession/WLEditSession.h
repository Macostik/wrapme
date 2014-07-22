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

@property (strong, nonatomic) NSMutableDictionary *original;

@property (strong, nonatomic) NSMutableDictionary *changed;

@property (weak, nonatomic) WLEntry* entry;

- (id)initWithEntry:(WLEntry *)entry;

- (void)setup:(NSMutableDictionary *)dictionary entry:(WLEntry *)entry;

- (void)apply:(NSMutableDictionary *)dictionary entry:(WLEntry *)entry;

- (void)apply:(WLEntry *)entry;

- (void)reset:(WLEntry *)entry;

- (BOOL)hasChanges;

@end
