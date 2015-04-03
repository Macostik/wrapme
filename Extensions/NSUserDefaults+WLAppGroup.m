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
        NSString *identifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"WLAppGroupIdentifier"];
        if (!identifier.nonempty) identifier = @"group.com.ravenpod.wraplive";
        appGroupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:identifier];
    }
    return appGroupUserDefaults;
}

@end
