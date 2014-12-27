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

@synthesize phones = _phones;

- (NSString *)phones {
    if (!_phones) {
        NSMutableString* phones = [NSMutableString string];
        for (WLDevice* device in self.devices) {
            if (device.phone.length == 0) continue;
            if (phones.length > 0) [phones appendString:@"\n"];
            [phones appendString:device.phone];
        }
        if (phones.length > 0) {
            _phones = [phones copy];
        } else {
            _phones = WLLS(@"No registered devices");
        }
    }
    return _phones;
}

@end
