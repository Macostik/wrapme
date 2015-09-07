//
//  NSURL+WLRemoteEntryHandler.h
//  meWrap
//
//  Created by Ravenpod on 12/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const WLURLScheme = @"mewrap";

@interface NSURL (WLRemoteEntryHandler)

+ (instancetype)WLURLWithPath:(NSString*)path;

+ (instancetype)WLURLForRemoteEntryWithKey:(NSString*)key identifier:(NSString*)identifier;

@end
