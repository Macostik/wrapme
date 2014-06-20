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
#import "WLUser.h"
#import <objc/runtime.h>
#import "NSObject+AssociatedObjects.h"
#import "WLEntry+Extended.h"

@interface WLContact ()

+ (void)contact:(ABRecordRef)record completion:(WLContactBlock)completion;

@end

@implementation WLContact

+ (void)contact:(ABRecordRef)record completion:(WLContactBlock)completion {
	NSArray* phones = WLAddressBookGetPhones(record);
	if (phones.nonempty) {
		WLContact* contact = [WLContact new];
		contact.name = WLAddressBookGetName(record);
		contact.phones = phones;
        [contact.phones makeObjectsPerformSelector:@selector(setName:) withObject:contact.name];
		if (ABPersonHasImageData(record)) {
			NSString* identifier = [NSString stringWithFormat:@"addressbook_%d", ABRecordGetRecordID(record)];
			WLStringBlock complete = ^(NSString* path) {
				WLPicture* picture = [WLPicture new];
				picture.large = path;
				picture.medium = path;
				picture.small = path;
				[contact.phones makeObjectsPerformSelector:@selector(setPicture:) withObject:picture];
				completion(contact);
			};
			if ([[WLImageCache cache] containsObjectWithIdentifier:identifier]) {
				complete([[WLImageCache cache] pathWithIdentifier:identifier]);
			} else {
				NSData* imageData = WLAddressBookGetImage(record);
				if (imageData) {
					[[WLImageCache cache] setImageData:imageData withIdentifier:identifier completion:complete];
				} else {
					completion(contact);
				}
			}
		} else {
			completion(contact);
		}
	} else {
		completion(nil);
	}
}

static inline NSArray* WLAddressBookGetPhones(ABRecordRef record) {
	NSMutableArray* wlphones = [NSMutableArray array];
    ABMultiValueRef phones = ABRecordCopyValue(record,kABPersonPhoneProperty);
	CFIndex count = ABMultiValueGetCount(phones);
	for (CFIndex index = 0; index < count; ++index) {
		WLPhone* phone = [[WLPhone alloc] init];
		phone.number = phoneNumberClearing((__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phones, index));
		if (phone.number.length >= WLMinPhoneLenth) {
			CFStringRef phoneLabel = ABMultiValueCopyLabelAtIndex(phones, index);
			phone.number.label = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(phoneLabel);
			if (phoneLabel != NULL) {
				CFRelease(phoneLabel);
			}
			[wlphones addObject:phone];
		}
    }
	if (phones != NULL) {
		CFRelease(phones);
	}
    return [wlphones copy];
}

static inline NSString* WLAddressBookGetName(ABRecordRef record) {
    NSString* firstName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    NSString* lastName  = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    return [[NSString stringWithFormat:@"%@ %@",WLString(firstName),WLString(lastName)] trim];
}

static inline NSData* WLAddressBookGetImage(ABRecordRef record) {
	return (__bridge_transfer NSData *)ABPersonCopyImageData(record);
}

- (NSString *)name {
	if (!_name.nonempty) {
		_name = [[self.phones selectObject:^BOOL(WLPhone* phone) {
			return phone.user.name.nonempty;
		}] name];
	}
	if (!_name.nonempty) {
		_name = [[self.phones selectObject:^BOOL(WLPhone* phone) {
			return phone.number.nonempty;
		}] phoneNumber];
	}
	return _name;
}

@end

@implementation WLPhone

- (BOOL)isEqualToPhone:(WLPhone *)phone {
    if (self.user) {
        return [self.user isEqualToEntry:phone.user];
    } else {
        return [self.number isEqualToString:phone.number];
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

@implementation WLAddressBook

+ (void)contacts:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	[self addressBook:^(ABAddressBookRef addressBook) {
		CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(addressBook);
		CFIndex count = ABAddressBookGetPersonCount(addressBook);
		if (count > 0) {
			run_in_default_queue(^{
				__block CFIndex done = 0;
				NSMutableArray* contacts = [NSMutableArray array];
				for (CFIndex i = 0; i < count; i++) {
					[WLContact contact:CFArrayGetValueAtIndex(records, i) completion:^(WLContact *contact) {
						done++;
						if (contact) {
							[contacts addObject:contact];
						}
						if (done == count) {
							CFRelease(records);
							run_in_main_queue(^{
								if (contacts.nonempty) {
									success([contacts copy]);
								} else {
									failure([NSError errorWithDescription:@"You don't have contacts with phone numbers on this device."]);
								}
							});
						}
					}];
				}
			});
		} else {
			if (records != NULL) {
				CFRelease(records);
			}
			failure([NSError errorWithDescription:@"You don't have contacts on this device."]);
		}
	} failure:failure];
}

+ (void)addressBook:(void (^)(ABAddressBookRef addressBook))success failure:(void (^)(NSError *))failure {
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
		run_in_main_queue(^{
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
