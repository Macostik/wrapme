//
//  WLAddressBook.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAddressBook.h"
#import <AddressBook/AddressBook.h>
#import "NSError+WLAPIManager.h"
#import "NSArray+Additions.h"
#import "NSString+Additions.h"

@interface WLUser (WLAddressBook)

+ (NSArray*)usersFromRecord:(ABRecordRef)record;

@end

@implementation WLAddressBook

+ (void)contacts:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error) {
				failure((__bridge NSError *)(error));
			} else if (granted) {
				success(WLAddressBookGetContacts(addressBook));
			} else {
				failure([NSError errorWithDescription:@"Access to your Address Book is not granted."]);
			}
		});
	});
}

static inline NSArray* WLAddressBookGetContacts(ABAddressBookRef addressBook) {
    CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex count = ABAddressBookGetPersonCount(addressBook);
    NSMutableArray* contacts = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(records, i);
		[contacts addObjectsFromArray:[WLUser usersFromRecord:record]];
    }
    CFRelease(records);
    return [contacts copy];
}

@end

@implementation WLUser (WLAddressBook)

+ (NSArray*)usersFromRecord:(ABRecordRef)record {
	NSString* name = WLAddressBookGetName(record);
	NSArray* phoneNumbers = WLAddressBookGetPhoneNumbers(record);
	return [phoneNumbers map:^id(NSString* phoneNumber) {
		WLUser* user = [WLUser entry];
		user.phoneNumber = phoneNumber;
		user.name = name;
		return user;
	}];
}

static inline NSArray* WLAddressBookGetPhoneNumbers(ABRecordRef record) {
	NSMutableArray* phoneNumbers = [NSMutableArray array];
    ABMultiValueRef _phoneNumbers = ABRecordCopyValue(record,kABPersonPhoneProperty);
	CFIndex count = ABMultiValueGetCount(_phoneNumbers);
	for (CFIndex index = 0; index < count; ++index) {
        NSString* phoneNumber = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(_phoneNumbers, index);
		phoneNumber = WLAddressBookClearPhoneNumber(phoneNumber);
		[phoneNumbers addObject:phoneNumber];
    }
    CFRelease(_phoneNumbers);
    return [phoneNumbers copy];
}

static inline NSString* WLAddressBookClearPhoneNumber(NSString* phoneNumber) {
	NSMutableString* _phoneNumber = [NSMutableString string];
	for (NSInteger index = 0; index < phoneNumber.length; ++index) {
		NSString* character = [phoneNumber substringWithRange:NSMakeRange(index, 1)];
		if ([character rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) {
			[_phoneNumber appendString:character];
		} else if ([character rangeOfString:@"+"].location != NSNotFound) {
			[_phoneNumber appendString:character];
		}
	}
	return [_phoneNumber copy];
}

static inline NSString* WLAddressBookGetName(ABRecordRef record) {
    NSString* firstName = nil;
    NSString* lastName = nil;
    firstName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    lastName  = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    return [[NSString stringWithFormat:@"%@ %@",firstName ? : @"",lastName ? : @""] trim];
}

@end
