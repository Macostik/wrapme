//
//  WLTempWrap.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/24/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLTempWrap.h"
#import "WLWrap.h"
#import "WLPicture.h"
#import "WLUser+Extended.h"
#import "NSOrderedSet+Additions.h"

@implementation WLTempWrap

- (void)setupEntry:(WLWrap *)wrap {
    self.wrap = wrap;
    self.name = wrap.name;
    WLPicture *picture = [WLPicture new];
    picture.large = wrap.picture.large;
    self.picture = picture;
    self.contributors = [NSOrderedSet orderedSetWithOrderedSet:wrap.contributors];
    self.contributor = wrap.contributor;
}

- (void)setContributors:(NSOrderedSet *)contributors {
    _contributors = [contributors mutate:^(NSMutableOrderedSet *mutableCopy) {
        [mutableCopy sortUsingComparator:^NSComparisonResult(WLUser *contributor1, WLUser *contributor2) {
            if ([contributor1 isCurrentUser]) {
                return NSOrderedAscending;
            } else if ([contributor2 isCurrentUser]) {
                return NSOrderedDescending;
            } else if (![self.wrap.contributors containsObject:contributor1] && ![self.wrap.contributors containsObject:contributor2]) {
                return [contributor1.name compare:contributor2.name];
            } else if (![self.wrap.contributors containsObject:contributor1]) {
                return NSOrderedDescending;
            } else if (![self.wrap.contributors containsObject:contributor2]) {
                return NSOrderedAscending;
            } else {
                return [contributor1.name compare:contributor2.name];
            }
        }];
    }];
}

@end