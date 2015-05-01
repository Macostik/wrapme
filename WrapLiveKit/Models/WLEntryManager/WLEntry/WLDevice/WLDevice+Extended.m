//
//  WLDevice+Extended.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/10/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDevice+Extended.h"
#import "WLEntryManager.h"

@implementation WLDevice (Extended)

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
    return [dictionary stringForKey:@"device_uid"];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    NSString* name = [dictionary stringForKey:@"device_name"];
    if (!NSStringEqual(self.name, name)) self.name = name;
    NSString* phone = [dictionary stringForKey:WLFullPhoneNumberKey];
    if (!NSStringEqual(self.phone, phone)) self.phone = phone;
    BOOL activated = [dictionary boolForKey:@"activated"];
    if (self.activated != activated) self.activated = activated;
    if (relatedEntry && self.owner != relatedEntry) self.owner = relatedEntry;
    return [super API_setup:dictionary relatedEntry:relatedEntry];
}

@end
