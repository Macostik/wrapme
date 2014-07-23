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
#import "NSString+Additions.h"

@implementation WLPerson

@synthesize name = _name;
@synthesize picture = _picture;
@synthesize phone = _phone;
@synthesize user = _user;

- (BOOL)isEqualToPerson:(WLPerson*)person {
    if (self.user) {
        return [self.user isEqualToEntry:person.user];
    } else {
        return [self.phone isEqualToString:person.phone];
    }
}

- (NSString *)prioritetName {
    if ([_user.name nonempty]) {
        return _user.name;
    } else if ([_name nonempty]) {
        return _name;
    } else {
        return _phone;
    }
}

- (WLPicture *)prioritetPicture {
    if (_user.picture) {
        return _user.picture;
    } else {
        return _picture;
    }
}

@end
