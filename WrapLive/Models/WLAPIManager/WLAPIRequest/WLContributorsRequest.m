//
//  WLContributorsRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContributorsRequest.h"
#import "WLAddressBook.h"
#import "WLPerson.h"

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
        __strong typeof(self)strongSelf = self;
        [WLAddressBook contacts:^(NSArray *contacts) {
            strongSelf.contacts = contacts;
            [super send];
        } failure:^(NSError *error) {
            [strongSelf handleFailure:error];
        }];
        return nil;
    } else {
        return [super send];
    }
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    NSArray* contacts = self.contacts;
    NSMutableArray* phones = [NSMutableArray array];
	[contacts all:^(WLContact* contact) {
		[contact.persons all:^(WLPerson* person) {
			[phones addObject:person.phone];
		}];
	}];
    [parameters trySetObject:phones forKey:@"phone_numbers"];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    NSArray* contacts = self.contacts;
    NSArray* users = response.data[@"users"];
	[contacts all:^(WLContact* contact) {
        NSMutableArray* personsToRemove = [NSMutableArray array];
		[contact.persons all:^(WLPerson* person) {
			for (NSDictionary* userData in users) {
				if ([userData[@"address_book_number"] isEqualToString:person.phone]) {
                    WLUser * user = [WLUser API_entry:userData];
                    __block BOOL exists = NO;
                    [contact.persons all:^(WLPerson* _person) {
                        if (_person != person && _person.user == user) {
                            [personsToRemove addObject:person];
                            exists = YES;
                        }
                    }];
                    if (!exists) {
                        person.user = user;
                    }
                    break;
				}
			}
		}];
        contact.persons = [contact.persons arrayByRemovingObjectsFromArray:personsToRemove];
	}];
	return contacts;
}

@end
