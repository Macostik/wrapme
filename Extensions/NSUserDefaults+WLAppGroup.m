//
//  NSUserDefaults+WLAppGroup.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSUserDefaults+WLAppGroup.h"

@implementation NSUserDefaults (WLAppGroup)

+ (instancetype)appGroupUserDefaults {
    return [[NSUserDefaults alloc] initWithSuiteName:WLAppGroupIdentifier];
}

@end
