//
//  NSUserDefaults+WLAppGroup.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const WLAppGroupEncryptedAuthorization = @"encrypted_authorization";

static inline NSString *AppGroupIdentifier(void) {
    static NSString *identifier = nil;
    if (!identifier) {
        identifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppGroupIdentifier"];
        if (identifier.length == 0) identifier = @"group.com.ravenpod.wraplive";
    }
    return identifier;
}

@interface NSUserDefaults (WLAppGroup)

+ (instancetype)appGroupUserDefaults;

@end
