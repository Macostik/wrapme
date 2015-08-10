//
//  NSURL+WLRemoteEntryHandler.h
//  moji
//
//  Created by Ravenpod on 12/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const WLURLScheme = @"moji";

@interface NSURL (WLRemoteEntryHandler)

+ (instancetype)WLURLWithPath:(NSString*)path;

+ (instancetype)WLURLForRemoteEntryWithKey:(NSString*)key identifier:(NSString*)identifier;

@end
