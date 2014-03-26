//
//  WLAddressBook.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAddressBook.h"
#import "WLUser.h"
#import <AddressBook/AddressBook.h>
#import "NSError+WLAPIManager.h"

@implementation WLAddressBook

+ (void)users:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error) {
				failure((__bridge NSError *)(error));
			} else if (granted) {
				success(WLAddressBookGetUsers(addressBook));
			} else {
				failure([NSError errorWithDescription:@"Access to your Address Book is not granted."]);
			}
		});
	});
}

+ (void)phoneNumbers:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error) {
				failure((__bridge NSError *)(error));
			} else if (granted) {
				success(WLAddressBookGetPhoneNumbers(addressBook));
			} else {
				failure([NSError errorWithDescription:@"Access to your Address Book is not granted."]);
			}
		});
	});
}

static inline NSString* WLAddressBookGetPhoneNumber(ABRecordRef record) {
    NSString* email = nil;
    ABMultiValueRef emails = ABRecordCopyValue(record,kABPersonPhoneProperty);
    if (ABMultiValueGetCount(emails) > 0) {
        email = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, 0);
    }
    CFRelease(emails);
    return email;
}

static inline NSString* WLAddressBookGetName(ABRecordRef record) {
    NSString* firstName = nil;
    NSString* lastName = nil;
    
    firstName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    lastName  = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    
    return [NSString stringWithFormat:@"%@ %@",firstName ? : @"",lastName ? : @""];
}

static inline NSDate* WLAddressBookGetBirthday(ABRecordRef record) {
    NSDate* birthday = nil;
    birthday = (__bridge NSDate *)(ABRecordCopyValue(record, kABPersonBirthdayProperty));
    return birthday;
}

static inline NSArray* WLAddressBookGetUsers(ABAddressBookRef addressBook) {
    CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    CFIndex count = ABAddressBookGetPersonCount(addressBook);
    
    NSMutableArray* users = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(records, i);
        
		NSString* phoneNumber = WLAddressBookGetPhoneNumber(record);
		
		if (phoneNumber.length > 0) {
			WLUser* user = [[WLUser alloc] init];
			user.name = WLAddressBookGetName(record);
			user.phoneNumber = phoneNumber;
			user.birthdate = WLAddressBookGetBirthday(record);
			[users addObject:user];
		}
    }
    
    CFRelease(records);
    
    return [users copy];
}

static inline NSArray* WLAddressBookGetPhoneNumbers(ABAddressBookRef addressBook) {
    CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    CFIndex count = ABAddressBookGetPersonCount(addressBook);
    
    NSMutableArray* phoneNumbers = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(records, i);
		ABMultiValueRef _phoneNumbers = ABRecordCopyValue(record,kABPersonPhoneProperty);
		CFIndex phoneCount = ABMultiValueGetCount(_phoneNumbers);
		for (NSInteger index = 0; index < phoneCount; ++index) {
			NSString* phoneNumber = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(_phoneNumbers, index);
			[phoneNumbers addObject:phoneNumber];
		}
		CFRelease(_phoneNumbers);
    }
    
    CFRelease(records);
    
    return [phoneNumbers copy];
}

@end
