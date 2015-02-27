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
        [WLAddressBook contacts:^(NSArray *contacts) {
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
    NSArray* contacts = self.contacts;
    NSArray* users = response.data[@"users"];
	[contacts all:^(WLAddressBookRecord* contact) {
        NSMutableArray* personsToRemove = [NSMutableArray array];
		[contact.phoneNumbers all:^(WLAddressBookPhoneNumber* person) {
			for (NSDictionary* userData in users) {
				if ([userData[@"address_book_number"] isEqualToString:person.phone]) {
                    WLUser * user = [WLUser API_entry:userData];
                    __block BOOL exists = NO;
                    [contact.phoneNumbers all:^(WLAddressBookPhoneNumber* _person) {
                        if (_person != person && _person.user == user) {
                            [personsToRemove addObject:person];
                            exists = YES;
                        }
                    }];
                    if (!exists) {
                        person.user = user;
                        person.activated = [userData integerForKey:WLSignInCountKey] > 0;
                    }
                    break;
				}
			}
		}];
        contact.phoneNumbers = [contact.phoneNumbers arrayByRemovingObjectsFromArray:personsToRemove];
	}];
	return contacts;
}

@end
