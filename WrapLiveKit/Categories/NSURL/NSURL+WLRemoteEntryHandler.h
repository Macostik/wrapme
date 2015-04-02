//
//  NSURL+WLRemoteEntryHandler.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const WLURLScheme = @"wraplive";

@interface NSURL (WLRemoteEntryHandler)

+ (instancetype)WLURLWithPath:(NSString*)path;

+ (instancetype)WLURLForRemoteEntryWithKey:(NSString*)key identifier:(NSString*)identifier;

@end
