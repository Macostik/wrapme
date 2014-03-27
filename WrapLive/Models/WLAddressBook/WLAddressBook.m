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

@interface WLContact ()

- (instancetype)initWithRecord:(ABRecordRef)record;

@end

@implementation WLAddressBook

+ (void)contacts:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
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
		WLContact* contact = [[WLContact alloc] initWithRecord:record];
		if ([contact.phoneNumbers count] > 0) {
			[contacts addObject:contact];
		}
    }
    CFRelease(records);
    return [contacts copy];
}

@end

@implementation WLContact

- (instancetype)initWithRecord:(ABRecordRef)record {
    self = [super init];
    if (self) {
        self.name = WLAddressBookGetName(record);
		self.phoneNumbers = WLAddressBookGetPhoneNumbers(record);
		self.birthdate = WLAddressBookGetBirthday(record);
    }
    return self;
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
    return [NSString stringWithFormat:@"%@ %@",firstName ? : @"",lastName ? : @""];
}

static inline NSDate* WLAddressBookGetBirthday(ABRecordRef record) {
    NSDate* birthday = nil;
    birthday = (__bridge NSDate *)(ABRecordCopyValue(record, kABPersonBirthdayProperty));
    return birthday;
}

@end
