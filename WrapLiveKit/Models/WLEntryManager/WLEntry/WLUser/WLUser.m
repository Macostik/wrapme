//
//  WLUser.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/10/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUser.h"
#import "WLContribution.h"
#import "WLDevice.h"
#import "WLWrap.h"


@implementation WLUser

@dynamic current;
@dynamic firstTimeUse;
@dynamic name;
@dynamic contributions;
@dynamic wraps;
@dynamic devices;
@dynamic editings;

@synthesize phones = _phones;
@synthesize securePhones = _securePhones;

- (NSString *)phones:(BOOL)secure {
    BOOL isCurrentUser = self.current;
    NSMutableString* phones = [NSMutableString string];
    for (WLDevice* device in self.devices) {
        NSString *phone = device.phone;
        if (phone.length == 0) continue;
        if (phones.length > 0) [phones appendString:@"\n"];
        if (!isCurrentUser && secure && phone.length > 4) {
            NSMutableString *_phone = [phone mutableCopy];
            for (NSUInteger index = 0; index < phone.length - 4; ++index) {
                [_phone replaceCharactersInRange:NSMakeRange(index, 1) withString:@"*"];
            }
            phone = [_phone copy];
        }
        [phones appendString:phone];
    }
    return [phones copy];
}

- (NSString *)phones {
    if (!_phones) {
        NSString* phones = [self phones:NO];
        _phones = (phones.length > 0) ? phones : WLLS(@"No registered devices");
    }
    return _phones;
}

- (NSString *)securePhones {
    if (!_securePhones) {
        NSString* phones = [self phones:YES];
        _securePhones = (phones.length > 0) ? phones : @"No registered devices";
    }
    return _securePhones;
}

@end
