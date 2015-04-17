//
//  NSUserDefaults+WLAppGroup.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSUserDefaults+WLAppGroup.h"
#import "NSString+Additions.h"

@implementation NSUserDefaults (WLAppGroup)

+ (instancetype)appGroupUserDefaults {
    static NSUserDefaults *appGroupUserDefaults = nil;
    if (!appGroupUserDefaults) {
        appGroupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:WLAppGroupIdentifier()];
    }
    return appGroupUserDefaults;
}

@end
