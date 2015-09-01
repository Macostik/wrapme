//
//  WLDevice+Extended.m
//  moji
//
//  Created by Ravenpod on 11/10/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDevice+Extended.h"
#import "WLEntryManager.h"

@implementation WLDevice (Extended)

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
    return [dictionary stringForKey:@"device_uid"];
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    NSString* name = [dictionary stringForKey:@"device_name"];
    if (!NSStringEqual(self.name, name)) self.name = name;
    NSString* phone = [dictionary stringForKey:WLFullPhoneNumberKey];
    if (!NSStringEqual(self.phone, phone)) self.phone = phone;
    BOOL activated = [dictionary boolForKey:@"activated"];
    if (self.activated != activated) self.activated = activated;
    if (container && self.owner != container) self.owner = container;
    NSDate* invitedAt = [dictionary timestampDateForKey:@"invited_at_in_epoch"];
    if (!NSDateEqual(self.invitedAt, invitedAt)) self.invitedAt = invitedAt;
    NSString* invitedBy = [dictionary stringForKey:@"invited_by_user_uid"];
    if (!NSStringEqual(self.invitedBy, invitedBy)) self.invitedBy = invitedBy;
    return [super API_setup:dictionary container:container];
}

@end
