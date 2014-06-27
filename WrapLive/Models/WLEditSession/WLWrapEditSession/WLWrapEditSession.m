//
//  WLWrapEditSession.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWrapEditSession.h"
#import "NSArray+Additions.h"
#import "WLWrap.h"

@implementation WLWrapEditSession

- (void) setupSessionWithEntry:(WLWrap *)wrap {
    self.originalEntry = [[WLTempWrap alloc] initWithEntry:wrap];
    self.changedEntry = [[WLTempWrap alloc] initWithEntry:wrap];
}

- (BOOL)hasChanges {
    if (![self.changedEntry.name isEqualToString:self.originalEntry.name]) {
        return YES;
    } else if (![self.changedEntry.picture.large isEqualToString:self.originalEntry.picture.large]) {
        return YES;
    } else if (self.changedEntry.invitees.nonempty) {
        return YES;
    } else if ([self.changedEntry.contributors count] != [self.originalEntry.contributors count]) {
		return YES;
	} else {
        return ![self.changedEntry.contributors isSubsetOfOrderedSet:self.originalEntry.contributors];
	}
}

- (void)applyTempEntry:(WLTempWrap *)tempWrap intoEntry:(WLWrap *)wrap {
    wrap.name = tempWrap.name;
    if (!wrap.picture) {
        WLPicture * picture = [[WLPicture alloc] init];
        wrap.picture = picture;
    }
    wrap.picture.large = tempWrap.picture.large;
    wrap.contributors = tempWrap.contributors;
    wrap.invitees = tempWrap.invitees;
}

@end
