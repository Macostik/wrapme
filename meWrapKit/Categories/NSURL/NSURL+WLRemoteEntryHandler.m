//
//  NSURL+WLRemoteEntryHandler.m
//  meWrap
//
//  Created by Ravenpod on 12/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSURL+WLRemoteEntryHandler.h"
#import "WLEntryKeys.h"

@implementation NSURL (WLRemoteEntryHandler)

+ (instancetype)WLURLWithPath:(NSString *)path {
    return [[self alloc] initWithScheme:WLURLScheme host:nil path:path];
}

+ (instancetype)WLURLForRemoteEntryWithKey:(NSString *)key identifier:(NSString *)identifier{
    return [self WLURLWithPath:[NSString stringWithFormat:@"/%@/?%@=%@", key, WLUIDKey, identifier]];
}

@end
