//
//  WLPerson.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPerson.h"
#import "WLUser.h"
#import "WLEntry+Extended.h"

@implementation WLPerson

@synthesize name;
@synthesize picture;
@synthesize phone;

- (BOOL)isEqualToPerson:(WLPerson*)person {
    if (self.user) {
        return [self.user isEqualToEntry:person.user];
    } else {
        return [self.phone isEqualToString:person.phone];
    }
}

@end
