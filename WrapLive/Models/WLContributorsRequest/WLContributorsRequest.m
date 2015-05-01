//
//  WLContributorsRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorsRequest.h"
#import "WLAddressBook.h"

@implementation WLContributorsRequest

+ (NSString *)defaultMethod {
    return @"POST";
}

+ (instancetype)request:(NSArray *)contacts {
    WLContributorsRequest* request = [WLContributorsRequest request];
    request.contacts = contacts;
    return request;
}

- (NSString *)path {
    return @"users/sign_up_status";
}

- (id)send {
    if (!self.contacts.nonempty) {
        [[WLAddressBook addressBook] contacts:^(NSArray *contacts) {
            self.contacts = contacts;
            [super send];
        } failure:^(NSError *error) {
            [self handleFailure:error];
        }];
        return nil;
    } else {
        return [super send];
    }
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    NSArray* contacts = self.contacts;
    NSMutableArray* phones = [NSMutableArray array];
	[contacts all:^(WLAddressBookRecord* contact) {
		[contact.phoneNumbers all:^(WLAddressBookPhoneNumber* person) {
			[phones addObject:person.phone];
		}];
	}];
    [parameters trySetObject:phones forKey:@"phone_numbers"];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    NSMutableArray* contacts = [self.contacts mutableCopy];
    NSArray* users = response.data[@"users"];
	[contacts removeObjectsWhileEnumerating:^BOOL (WLAddressBookRecord* contact) {
        NSMutableArray *phoneNumbers = [contact.phoneNumbers mutableCopy];
        [phoneNumbers removeObjectsWhileEnumerating:^BOOL (WLAddressBookPhoneNumber *phoneNumber) {
            NSDictionary *userData = [[users objectsWhere:@"address_book_number == %@", phoneNumber.phone] lastObject];
            if (userData) {
                WLUser *user = [WLUser API_entry:userData];
                if ([user isCurrentUser]) {
                    return YES;
                } else {
                    for (WLAddressBookPhoneNumber* _phoneNumber in contact.phoneNumbers) {
                        if (_phoneNumber != phoneNumber && _phoneNumber.user == user) {
                            return YES;
                        }
                    }
                    phoneNumber.user = user;
                    phoneNumber.activated = [userData integerForKey:WLSignInCountKey] > 0;
                }
            }
            return NO;
        }];
        if (phoneNumbers.nonempty) {
            contact.phoneNumbers = [phoneNumbers copy];
            return NO;
        } else {
            return YES;
        }
	}];
	return [contacts copy];
}

@end
