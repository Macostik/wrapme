//
//  WLUser.m
//  meWrap
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUser.h"
#import "WLCandy.h"
#import "WLContribution.h"
#import "WLDevice.h"
#import "WLWrap.h"
#import "WLLocalization.h"

@implementation WLUser

@dynamic current;
@dynamic firstTimeUse;
@dynamic name;
@dynamic contributions;
@dynamic devices;
@dynamic editings;
@dynamic wraps;

@synthesize phones = _phones;
@synthesize securePhones = _securePhones;

- (NSString *)phones:(BOOL)secure {
    BOOL current = self.current;
    NSMutableString* phones = [NSMutableString string];
    for (WLDevice* device in self.devices) {
        NSString *phone = device.phone;
        if (phone.length == 0) continue;
        if (phones.length > 0) [phones appendString:@"\n"];
        if (!current && secure && phone.length > 4) {
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
        _phones = (phones.length > 0) ? phones : WLLS(@"no_devices");
    }
    return _phones;
}

- (NSString *)securePhones {
    if (!_securePhones) {
        NSString* phones = [self phones:YES];
        _securePhones = (phones.length > 0) ? phones : WLLS(@"no_devices");
    }
    return _securePhones;
}

- (void)addWrap:(WLWrap *)wrap {
    [self addWrapsObject:wrap];
}

- (void)removeWrap:(WLWrap *)wrap {
    [self removeWrapsObject:wrap];
}

- (NSMutableOrderedSet *)sortedWraps {
    return [[NSMutableOrderedSet orderedSetWithSet:self.wraps] sortByUpdatedAt];
}

- (BOOL)isSignupCompleted {
    return self.name.nonempty && self.picture.medium.nonempty;
}

- (BOOL)isInvited {
    if ([self current]) return NO;
    NSSet *devices = self.devices;
    if (devices.nonempty) {
        for (WLDevice *device in devices) {
            if (device.activated) {
                return NO;
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (NSDate *)invitedAt {
    return [(WLDevice*)[self.devices anyObject] invitedAt];
}

- (NSString *)invitationHintText {
    NSDate *invitedAt = self.invitedAt;
    if (invitedAt) {
        return [NSString stringWithFormat:@"Invite sent %@. Swipe to resend invite", [invitedAt stringWithDateStyle:NSDateFormatterLongStyle]];
    } else {
        return @"Invite sent. Swipe to resend invite";
    }
}

@end

@implementation WLUser (CurrentUser)

static WLUser *currentUser = nil;

+ (WLUser*)currentUser {
    if (!currentUser) {
        WLUser *currentUser = [[WLUser entriesWhere:@"current == TRUE"] lastObject];
        if (currentUser) {
            [self setCurrentUser:currentUser];
        }
    }
    return currentUser;
}

+ (void)setCurrentUser:(WLUser*)user {
    if (currentUser != user) {
        if (currentUser) {
            currentUser.current = NO;
        }
        currentUser = user;
        if (user) {
            if (!user.current) user.current = YES;
        }
    }
}

- (void)setCurrent {
    [WLUser setCurrentUser:self];
}

@end
