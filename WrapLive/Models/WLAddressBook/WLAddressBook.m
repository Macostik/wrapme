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
#import "WLAddressBookPhoneNumber.h"
#import "WLAddressBookRecord.h"

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
					[WLAddressBookRecord record:CFArrayGetValueAtIndex(records, i) completion:^(WLAddressBookRecord *contact) {
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
