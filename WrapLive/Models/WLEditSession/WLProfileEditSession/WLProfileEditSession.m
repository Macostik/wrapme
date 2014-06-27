//
//  WLProfileEditSession.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProfileEditSession.h"
#import "WLTempProfile.h"
#import "WlUser.h"

@implementation WLProfileEditSession

- (void) setupSessionWithEntry:(WLUser *)user {
    self.originalEntry = [[WLTempProfile alloc] initWithEntry:user];
    self.changedEntry = [[WLTempProfile alloc] initWithEntry:user];
}

- (BOOL)hasChanges {
    if (![self.changedEntry.name isEqualToString:self.originalEntry.name]) {
        return YES;
    } else if (![self.changedEntry.email isEqualToString:self.originalEntry.email]) {
        return YES;
    } else if (![self.changedEntry.picture.large isEqualToString:self.originalEntry.picture.large]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)applyTempEntry:(WLTempProfile *)tempProfile intoEntry:(WLUser *)user {
    user.name = tempProfile.name;
    user.email = tempProfile.email;
    user.picture.large = tempProfile.picture.large;
}

@end
