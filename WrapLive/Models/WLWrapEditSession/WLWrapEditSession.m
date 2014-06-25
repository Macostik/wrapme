//
//  WLWrapEditSession.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWrapEditSession.h"
#import "WLPicture.h"
#import "WLWrap.h"

@implementation WLWrapEditSession

- (id)initWithWrap:(WLWrap *)wrap {
    self = [super init];
    if (self) {
        self.originalWrap = [[WLTempWrap alloc] initWithWrap:wrap];
        self.changedWrap = [[WLTempWrap alloc] initWithWrap:wrap];
    }
    return self;
}

- (BOOL)hasChanges {
    BOOL nameChanged = ![self.changedWrap.name isEqualToString:self.originalWrap.name];
	BOOL coverChanged = ![self.changedWrap.picture.large isEqualToString:self.originalWrap.picture.large];
	BOOL contributorsChanged = NO;
	
	if ([self.changedWrap.contributors count] != [self.originalWrap.contributors count]) {
		contributorsChanged = YES;
	} else {
        contributorsChanged = ![self.changedWrap.contributors isSubsetOfOrderedSet:self.originalWrap.contributors];
	}
    return (nameChanged || coverChanged || contributorsChanged);
}

- (void)applyChanges:(WLWrap *)wrap {
    [self applyWrap:self.changedWrap intoWrap:wrap];
}

- (void)resetChanges:(WLWrap *)wrap {
    [self applyWrap:self.originalWrap intoWrap:wrap];
}

- (void)applyWrap:(WLTempWrap *)tempWrap intoWrap:(WLWrap *)wrap {
    wrap.name = tempWrap.name;
    wrap.picture.large = tempWrap.picture.large;
    wrap.contributors = tempWrap.contributors;
    wrap.invitees = tempWrap.invitees;
}

@end
