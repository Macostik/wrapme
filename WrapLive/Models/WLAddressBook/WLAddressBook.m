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
#import "WLContributorsRequest.h"
#import "AsynchronousOperation.h"

@implementation WLAddressBook

static NSArray *cachedRecords = nil;

+ (void)cachedRecords:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    if (cachedRecords) {
        if (success) success(cachedRecords);
    } else {
        [self records:success failure:failure];
    }
}

+ (void)records:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [self addressBook:^(ABAddressBookRef addressBook) {
        [self records:addressBook success:success failure:failure];
    } failure:failure];
}

+ (void)records:(ABAddressBookRef)addressBook success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [WLAddressBook contacts:addressBook success:^(NSArray *array) {
        runUnaryAsynchronousOperation(@"wl_address_book_queue", ^(AsynchronousOperation *operation) {
            [[WLContributorsRequest request:array] send:^(id object) {
                cachedRecords = object;
                if (success) success(object);
                [operation finish];
            } failure:^(NSError *error) {
                if (failure) failure(error);
                [operation finish];
            }];
        });
    } failure:failure];
}

+ (void)updateCachedRecords:(ABAddressBookRef)addressBook {
    [WLAddressBook records:addressBook success:nil failure:nil];
}

void addressBookChanged (ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    Class class = [WLAddressBook class];
    [NSObject cancelPreviousPerformRequestsWithTarget:class selector:@selector(updateCachedRecords:) object:(__bridge id)(addressBook)];
    [class performSelector:@selector(updateCachedRecords:) withObject:(__bridge id)(addressBook) afterDelay:0.0f];
}

+ (void)beginCaching {
    [self addressBook:^(ABAddressBookRef addressBook) {
        [WLAddressBook records:addressBook success:nil failure:nil];
        ABAddressBookRegisterExternalChangeCallback(addressBook, addressBookChanged, NULL);
    } failure:^(NSError *error) {
    }];
}

+ (void)endCaching {
    [self addressBook:^(ABAddressBookRef addressBook) {
        ABAddressBookUnregisterExternalChangeCallback(addressBook, addressBookChanged, NULL);
    } failure:^(NSError *error) {
    }];
}

+ (void)contacts:(ABAddressBookRef)addressBook success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    runUnaryAsynchronousOperation(@"wl_address_book_queue", ^(AsynchronousOperation *operation) {
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
                                [operation finish];
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
            [operation finish];
        }
    });
}

+ (void)contacts:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	[self addressBook:^(ABAddressBookRef addressBook) {
        [self contacts:addressBook success:success failure:failure];
	} failure:failure];
}

+ (void)addressBook:(void (^)(ABAddressBookRef addressBook))success failure:(WLFailureBlock)failure {
    static ABAddressBookRef addressBook = NULL;
    if (addressBook == NULL) {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    }
    runUnaryAsynchronousOperation(@"wl_address_book_queue", ^(AsynchronousOperation *operation) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            run_in_main_queue(^{
                if (error) {
                    failure((__bridge NSError *)(error));
                } else if (granted) {
                    success(addressBook);
                } else {
                    failure([NSError errorWithDescription:WLLS(@"Access to your Address Book is not granted.")]);
                }
                [operation finish];
            });
        });
    });
}

@end
