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
#import "WLImageCache.h"

@interface WLUser (WLAddressBook)

+ (void)usersFromRecord:(ABRecordRef)record completion:(void (^)(NSArray* users))completion;

@end

@implementation WLAddressBook

+ (void)contacts:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
	[self addressBook:^(ABAddressBookRef addressBook) {
		CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(addressBook);
		CFIndex count = ABAddressBookGetPersonCount(addressBook);
		if (count > 0) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				NSMutableArray* contacts = [NSMutableArray array];
				for (int i = 0; i < count; i++) {
					ABRecordRef record = CFArrayGetValueAtIndex(records, i);
					[WLUser usersFromRecord:record completion:^(NSArray *users) {
						[contacts addObjectsFromArray:users];
						if (i == count - 1) {
							CFRelease(records);
							dispatch_async(dispatch_get_main_queue(), ^{
								success([contacts copy]);
							});
						}
					}];
				}
			});
			
		} else {
			CFRelease(records);
			failure([NSError errorWithDescription:@"You don't have contacts on this device."]);
		}
	} failure:failure];
}

+ (void)addressBook:(void (^)(ABAddressBookRef addressBook))success failure:(void (^)(NSError *))failure {
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error) {
				failure((__bridge NSError *)(error));
			} else if (granted) {
				success(addressBook);
			} else {
				failure([NSError errorWithDescription:@"Access to your Address Book is not granted."]);
			}
		});
	});
}

@end

@implementation WLUser (WLAddressBook)

+ (void)usersFromRecord:(ABRecordRef)record completion:(void (^)(NSArray *))completion {
	NSString* name = WLAddressBookGetName(record);
	NSArray* phoneNumbers = WLAddressBookGetPhoneNumbers(record);
	if ([phoneNumbers count] > 0) {
		void (^mapUsers)(NSString*) = ^ (NSString* imagePath) {
			completion([phoneNumbers map:^id(NSString* phoneNumber) {
				WLUser* user = [WLUser entry];
				user.phoneNumber = phoneNumber;
				user.name = name;
				if (imagePath.nonempty) {
					user.picture.small = imagePath;
					user.picture.medium = imagePath;
					user.picture.large = imagePath;
				}
				return user;
			}]);
		};
		if (ABPersonHasImageData(record)) {
			NSData* imageData = (__bridge_transfer NSData *)ABPersonCopyImageData(record);
			ABRecordID identifier = ABRecordGetRecordID(record);
			[[WLImageCache cache] setImageData:imageData withIdentifier:[NSString stringWithFormat:@"addressbook_%d", identifier] completion:mapUsers];
		} else {
			mapUsers(nil);
		}
	} else {
		completion(nil);
	}
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
    NSString* firstName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    NSString* lastName  = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    return [[NSString stringWithFormat:@"%@ %@",WLString(firstName),WLString(lastName)] trim];
}

@end
