//
//  WLEntry.m
//  meWrap
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntry.h"


@implementation WLEntry

@dynamic identifier;
@dynamic uploadIdentifier;
@dynamic updatedAt;
@dynamic picture;
@dynamic createdAt;
@dynamic unread;

- (NSComparisonResult)compare:(WLEntry *)entry {
    return [self.updatedAt compare:entry.updatedAt];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@", [[self class] displayName] ? : [self class], self.identifier];
}

@end
