//
//  WLAddressBookPhoneNumber.m
//  moji
//
//  Created by Oleg Vishnivetskiy on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAddressBookPhoneNumber.h"
#import "NSObject+AssociatedObjects.h"

@implementation WLAddressBookPhoneNumber

@synthesize name = _name;
@synthesize picture = _picture;
@synthesize phone = _phone;
@synthesize user = _user;

- (BOOL)isEqualToPerson:(WLAddressBookPhoneNumber*)person {
    if (self.user) {
        return [self.user isEqualToEntry:person.user];
    } else {
        return [self.phone isEqualToString:person.phone];
    }
}

- (NSString *)priorityName {
    if ([_user.name nonempty]) {
        return _user.name;
    } else if ([_name nonempty]) {
        return _name;
    } else {
        return _phone;
    }
}

- (WLPicture *)priorityPicture {
    if (_user.picture.small.nonempty) {
        return _user.picture;
    } else {
        return _picture;
    }
}

@end

@implementation NSString (WLAddressBook)

- (void)setLabel:(NSString *)label {
    [self setAssociatedObject:label forKey:"wl_address_book_label"];
}

- (NSString *)label {
    return [self associatedObjectForKey:"wl_address_book_label"];
}

@end
