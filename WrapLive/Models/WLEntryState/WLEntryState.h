//
//  WLEntryState.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@interface WLEntryState : NSObject

+ (NSDictionary*)stateWithEntry:(WLEntry*)entry;

+ (BOOL)read:(WLEntry*)entry;

+ (BOOL)updated:(WLEntry*)entry;

+ (void)getState:(WLEntry*)entry completion:(void (^)(BOOL read, BOOL updated))completion;

+ (void)setRead:(BOOL)read entry:(WLEntry*)entry;

+ (void)setUpdated:(BOOL)updated entry:(WLEntry*)entry;

+ (void)setRead:(BOOL)read updated:(BOOL)updated entry:(WLEntry*)entry;

@end

@interface WLEntry (WLEntryState)

- (BOOL)read;

- (BOOL)updated;

- (void)getState:(void (^)(BOOL read, BOOL updated))completion;

- (void)setRead:(BOOL)read;

- (void)setUpdated:(BOOL)updated;

- (void)setRead:(BOOL)read updated:(BOOL)updated;

@end
