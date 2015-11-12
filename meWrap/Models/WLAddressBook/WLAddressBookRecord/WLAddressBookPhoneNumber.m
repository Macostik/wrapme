//
//  WLAddressBookPhoneNumber.m
//  meWrap
//
//  Created by Oleg Vishnivetskiy on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAddressBookPhoneNumber.h"
#import "NSObject+AssociatedObjects.h"
#import "WLAddressBookRecord.h"

@implementation WLAddressBookPhoneNumber

@synthesize name = _name;
@synthesize picture = _picture;
@synthesize phone = _phone;
@synthesize user = _user;

- (BOOL)isEqualToPhoneNumber:(WLAddressBookPhoneNumber*)person {
    if (self.user) {
        return self.user == person.user;
    } else {
        return [self.phone isEqualToString:person.phone];
    }
}

- (NSString *)name {
    if (!_name) {
        if ([_user.name nonempty]) {
            _name = _user.name;
        } else if (self.record.name.nonempty) {
            _name = self.record.name;
        } else {
            _name = _phone;
        }
    }
    return _name;
}

- (Asset *)picture {
    if (!_picture) {
        if (_user.picture.small.nonempty) {
            _picture = _user.picture;
        } else {
            _picture = self.record.picture;
        }
    }
    return _picture;
}

- (NSString *)description {
    return self.phone;
}

@end
