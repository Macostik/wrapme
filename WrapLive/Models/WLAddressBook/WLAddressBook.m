//
//  WLAddressBook.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAddressBook.h"
#import <AddressBook/AddressBook.h>
#import <objc/runtime.h>
#import "NSObject+AssociatedObjects.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAddressBookRecord.h"

@interface WLAddressBook ()

@property (strong, nonatomic) NSArray *cachedRecords;

@end

@implementation WLAddressBook

+ (instancetype)addressBook {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (void)setCachedRecords:(NSArray *)cachedRecords {
    _cachedRecords = cachedRecords;
    [self broadcast:@selector(addressBook:didUpdateCachedRecords:) object:cachedRecords];
}

- (BOOL)cachedRecords:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    for (WLAddressBookRecord *record in self.cachedRecords) {
        for (WLAddressBookPhoneNumber *phoneNumber in record.phoneNumbers) {
            if (phoneNumber.user && !phoneNumber.user.valid) {
                self.cachedRecords = nil;
                break;
            }
        }
    }
    if (self.cachedRecords) {
        if (success) success(self.cachedRecords);
        return YES;
    } else {
        [self records:success failure:failure];
        return NO;
    }
}

- (void)records:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [self addressBook:^(ABAddressBookRef addressBook) {
        [self records:addressBook success:success failure:failure];
    } failure:failure];
}

- (void)records:(ABAddressBookRef)addressBook success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [self contacts:addressBook success:^(NSArray *array) {
        runUnaryQueuedOperation(@"wl_address_book_queue", ^(WLOperation *operation) {
            [[WLAPIRequest contributorsFromContacts:array] send:^(id object) {
                self.cachedRecords = object;
                if (success) success(object);
                [operation finish];
            } failure:^(NSError *error) {
                if (failure) failure(error);
                [operation finish];
            }];
        });
    } failure:failure];
}

static BOOL updateCachedRecordsFailed = NO;

- (void)updateCachedRecordsAfterFailure {
    if (updateCachedRecordsFailed) {
        [self updateCachedRecords];
    }
}

- (void)updateCachedRecords {
    [self addressBook:^(ABAddressBookRef addressBook) {
        [self updateCachedRecords:addressBook];
    } failure:nil];
}

- (void)updateCachedRecords:(ABAddressBookRef)addressBook {
    [self records:addressBook success:^(NSArray *array) {
        updateCachedRecordsFailed = NO;
    } failure:^(NSError *error) {
        updateCachedRecordsFailed = YES;
    }];
}

void addressBookChanged (ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    WLAddressBook *_addressBook = (__bridge WLAddressBook *)(context);
    if (_addressBook) {
        [_addressBook enqueueSelectorPerforming:@selector(updateCachedRecords:) afterDelay:.0f];
    }
}

- (void)beginCaching {
    [self addressBook:^(ABAddressBookRef addressBook) {
        [self records:addressBook success:nil failure:nil];
        ABAddressBookRegisterExternalChangeCallback(addressBook, addressBookChanged, (__bridge void *)(self));
    } failure:^(NSError *error) {
    }];
}

- (void)endCaching {
    [self addressBook:^(ABAddressBookRef addressBook) {
        ABAddressBookUnregisterExternalChangeCallback(addressBook, addressBookChanged, NULL);
    } failure:^(NSError *error) {
    }];
}

- (void)contacts:(ABAddressBookRef)addressBook success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    runUnaryQueuedOperation(@"wl_address_book_queue", ^(WLOperation *operation) {
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
                                    if (success) success([contacts copy]);
                                } else {
                                    if (failure) failure([NSError errorWithDescription:WLLS(@"no_contacts_with_phone_number")]);
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
            if (failure) failure([NSError errorWithDescription:WLLS(@"no_contacts")]);
            [operation finish];
        }
    });
}

- (void)contacts:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	[self addressBook:^(ABAddressBookRef addressBook) {
        [self contacts:addressBook success:success failure:failure];
	} failure:failure];
}

- (void)addressBook:(void (^)(ABAddressBookRef addressBook))success failure:(WLFailureBlock)failure {
    runUnaryQueuedOperation(@"wl_address_book_queue", ^(WLOperation *operation) {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            run_in_main_queue(^{
                if (error) {
                    if (failure) failure((__bridge NSError *)(error));
                } else if (granted) {
                    if (success) success(addressBook);
                } else {
                    if (failure) failure([NSError errorWithDescription:WLLS(@"no_access_to_contacts")]);
                }
                [operation finish];
            });
        });
    });
}

@end
