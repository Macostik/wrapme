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

@interface WLContact ()

+ (void)contact:(ABRecordRef)record completion:(WLContactBlock)completion;

@end

@implementation WLContact

+ (void)contact:(ABRecordRef)record completion:(WLContactBlock)completion {
	NSArray* users = WLAddressBookGetUsers(record);
	if ([users count] > 0) {
		WLContact* contact = [WLContact new];
		contact.name = WLAddressBookGetName(record);
		[users makeObjectsPerformSelector:@selector(setName:) withObject:contact.name];
		contact.users = users;
		if (ABPersonHasImageData(record)) {
			NSString* identifier = [NSString stringWithFormat:@"addressbook_%d", ABRecordGetRecordID(record)];
			
			WLStringBlock complete = ^(NSString* path) {
				WLPicture* picture = [WLPicture new];
				picture.large = path;
				picture.medium = path;
				picture.small = path;
				[contact.users makeObjectsPerformSelector:@selector(setPicture:) withObject:picture];
				completion(contact);
			};
			
			if ([[WLImageCache cache] containsObjectWithIdentifier:identifier]) {
				complete([[WLImageCache cache] pathWithIdentifier:identifier]);
			} else {
				[[WLImageCache cache] setImageData:WLAddressBookGetImage(record)
									withIdentifier:identifier
										completion:complete];
			}
		} else {
			completion(contact);
		}
	} else {
		completion(nil);
	}
}

static inline NSArray* WLAddressBookGetUsers(ABRecordRef record) {
	NSMutableArray* users = [NSMutableArray array];
    ABMultiValueRef phones = ABRecordCopyValue(record,kABPersonPhoneProperty);
	CFIndex count = ABMultiValueGetCount(phones);
	for (CFIndex index = 0; index < count; ++index) {
		WLUser* user = [WLUser entry];
		user.phoneNumber = WLAddressBookClearPhone((__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phones, index));
		if (user.phoneNumber.nonempty) {
			CFStringRef phoneLabel = ABMultiValueCopyLabelAtIndex(phones, index);
			user.phoneNumber.label = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(phoneLabel);
			if (phoneLabel != NULL) {
				CFRelease(phoneLabel);
			}
			[users addObject:user];
		}
    }
	if (phones != NULL) {
		CFRelease(phones);
	}
    return [users copy];
}

static inline NSString* WLAddressBookClearPhone(NSString* phone) {
	NSMutableString* _phone = [NSMutableString string];
	for (NSInteger index = 0; index < phone.length; ++index) {
		NSString* character = [phone substringWithRange:NSMakeRange(index, 1)];
		if ([character rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) {
			[_phone appendString:character];
		} else if ([character rangeOfString:@"+"].location != NSNotFound) {
			[_phone appendString:character];
		}
	}
	return [_phone copy];
}

static inline NSString* WLAddressBookGetName(ABRecordRef record) {
    NSString* firstName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    NSString* lastName  = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    return [[NSString stringWithFormat:@"%@ %@",WLString(firstName),WLString(lastName)] trim];
}

static inline NSData* WLAddressBookGetImage(ABRecordRef record) {
	return (__bridge_transfer NSData *)ABPersonCopyImageData(record);
}

- (BOOL)signedUp {
	for (WLUser* contributor in self.users) {
		if (contributor.identifier.nonempty) {
			return YES;
		}
	}
	return NO;
}

- (NSString *)name {
	if (!_name.nonempty) {
		_name = [[self.users selectObject:^BOOL(WLUser* user) {
			return user.name.nonempty;
		}] name];
	}
	if (!_name.nonempty) {
		_name = [[self.users selectObject:^BOOL(WLUser* user) {
			return user.phoneNumber.nonempty;
		}] phoneNumber];
	}
	return _name;
}

@end

@implementation NSString (WLAddressBook)

- (void)setLabel:(NSString *)label {
	[self setAssociatedObject:label forKey:@"wl_address_book_label"];
}

- (NSString *)label {
	return [self associatedObjectForKey:@"wl_address_book_label"];
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
								if ([contacts count] > 0) {
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
