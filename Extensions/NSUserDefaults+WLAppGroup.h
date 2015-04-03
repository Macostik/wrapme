//
//  NSUserDefaults+WLAppGroup.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const WLAppGroupEncryptedAuthorization = @"encrypted_authorization";

static NSString *const WLAppGroupEnvironment = @"environment";

@interface NSUserDefaults (WLAppGroup)

+ (instancetype)appGroupUserDefaults;

@end
