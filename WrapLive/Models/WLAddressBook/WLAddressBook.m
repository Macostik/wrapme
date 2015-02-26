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
#import "WLPerson.h"

@interface WLAddressBookRecord ()

+ (void)contact:(ABRecordRef)record completion:(WLContactBlock)completion;

@end

@implementation WLAddressBookRecord

+ (void)contact:(ABRecordRef)record completion:(WLContactBlock)completion {
	NSArray* phones = WLAddressBookGetPhones(record);
	if (phones.nonempty) {
		WLAddressBookRecord* contact = [WLAddressBookRecord new];
		contact.name = WLAddressBookGetName(record);
		contact.persons = phones;
        [contact.persons makeObjectsPerformSelector:@selector(setName:) withObject:contact.name];
		if (ABPersonHasImageData(record)) {
			NSString* identifier = [NSString stringWithFormat:@"addressbook_%d", ABRecordGetRecordID(record)];
			WLStringBlock complete = ^(NSString* path) {
				WLPicture* picture = [WLPicture new];
				picture.large = path;
				picture.medium = path;
				picture.small = path;
				[contact.persons makeObjectsPerformSelector:@selector(setPicture:) withObject:picture];
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
	NSMutableArray* wlpersons = [NSMutableArray array];
    ABMultiValueRef phones = ABRecordCopyValue(record,kABPersonPhoneProperty);
	CFIndex count = ABMultiValueGetCount(phones);
	for (CFIndex index = 0; index < count; ++index) {
		WLPerson* person = [[WLPerson alloc] init];
		person.phone = phoneNumberClearing((__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phones, index));
		if (person.phone.length >= WLMinPhoneLenth) {
			CFStringRef phoneLabel = ABMultiValueCopyLabelAtIndex(phones, index);
			person.phone.label = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(phoneLabel);
			if (phoneLabel != NULL) {
				CFRelease(phoneLabel);
			}
			[wlpersons addObject:person];
		}
    }
	if (phones != NULL) {
		CFRelease(phones);
	}
    return [wlpersons copy];
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
		_name = [[self.persons selectObject:^BOOL(WLPerson* person) {
			return person.user.name.nonempty;
		}] name];
	}
	if (!_name.nonempty) {
		_name = [[self.persons selectObject:^BOOL(WLPerson* person) {
			return person.phone.nonempty;
		}] phone];
	}
	return _name;
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
					[WLAddressBookRecord contact:CFArrayGetValueAtIndex(records, i) completion:^(WLAddressBookRecord *contact) {
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
									failure([NSError errorWithDescription:WLLS(@"You don't have contacts with phone numbers on this device.")]);
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
			failure([NSError errorWithDescription:WLLS(@"You don't have contacts on this device.")]);
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
				failure([NSError errorWithDescription:WLLS(@"Access to your Address Book is not granted.")]);
			}
		});
	});
}

+ (void)test:(ABAddressBookRef)addressBook {
    NSString* data = @"http://www.json-generator.com/api/json/get/cvUceAdHVK?indent=2";
    NSArray* users = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:data]] options:NSJSONReadingAllowFragments error:NULL];
    for (NSDictionary* user in users)
    {
        NSString* picture = [user objectForKey:@"picture"];
        // create an ABRecordRef
        ABRecordRef record = ABPersonCreate();
        
        // add the first name
        ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)([user objectForKey:@"fname"]), NULL);
        
        // add the last name
        ABRecordSetValue(record, kABPersonLastNameProperty, (__bridge CFTypeRef)([user objectForKey:@"lname"]), NULL);
        
        ABMutableMultiValueRef email = ABMultiValueCreateMutable(kABStringPropertyType);
        
        ABMultiValueAddValueAndLabel(email, (__bridge CFTypeRef)([user objectForKey:@"email"]), kABHomeLabel, NULL);
        
        // add the home email
        ABRecordSetValue(record, kABPersonEmailProperty, email, NULL);
        
        ABMutableMultiValueRef phone = ABMultiValueCreateMutable(kABStringPropertyType);
        
        for (NSString* p in [user objectForKey:@"phones"]) {
            ABMultiValueAddValueAndLabel(phone, (__bridge CFTypeRef)(p), kABHomeLabel, NULL);
        }
        
        ABRecordSetValue(record, kABPersonPhoneProperty, phone, NULL);
        
        ABPersonSetImageData(record, (__bridge CFDataRef)([NSData dataWithContentsOfURL:[NSURL URLWithString:picture]]), NULL);

        ABAddressBookAddRecord(addressBook, record, NULL);
    }
    
    // save the address book
    ABAddressBookSave(addressBook, NULL);
}

@end
