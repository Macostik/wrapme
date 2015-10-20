//
//  WLAddressBook.m
//  meWrap
//
//  Created by Ravenpod on 25.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAddressBook.h"
#import <AddressBook/AddressBook.h>
#import <objc/runtime.h>
#import "NSObject+AssociatedObjects.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAddressBookRecord.h"

@interface WLAddressBook ()

@property (strong, nonatomic) NSSet *cachedRecords;

@end

@implementation WLAddressBook

+ (instancetype)addressBook {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (void)setCachedRecords:(NSSet *)cachedRecords {
    _cachedRecords = cachedRecords;
    [self broadcast:@selector(addressBook:didUpdateCachedRecords:) object:cachedRecords];
}

- (BOOL)cachedRecords:(WLSetBlock)success failure:(WLFailureBlock)failure {
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

- (void)records:(WLSetBlock)success failure:(WLFailureBlock)failure {
    [self addressBook:^(ABAddressBookRef addressBook) {
        [self records:addressBook success:success failure:failure];
    } failure:failure];
}

- (void)records:(ABAddressBookRef)addressBook success:(WLSetBlock)success failure:(WLFailureBlock)failure {
    [self contacts:addressBook success:^(NSSet *array) {
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
        [self records:addressBook success:^(NSSet *array) {
            updateCachedRecordsFailed = NO;
        } failure:^(NSError *error) {
            updateCachedRecordsFailed = YES;
        }];
    } failure:nil];
}

void addressBookChanged (ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    [WLAddressBook addressBook]->sharedAddressBook = addressBook;
    [[WLAddressBook addressBook] enqueueSelectorPerforming:@selector(updateCachedRecords) afterDelay:.0f];
}

- (void)beginCaching {
    [self addressBook:^(ABAddressBookRef addressBook) {
        [self records:addressBook success:nil failure:nil];
        ABAddressBookRegisterExternalChangeCallback(addressBook, addressBookChanged, NULL);
    } failure:^(NSError *error) {
    }];
}

- (void)endCaching {
    [self addressBook:^(ABAddressBookRef addressBook) {
        ABAddressBookUnregisterExternalChangeCallback(addressBook, addressBookChanged, NULL);
    } failure:^(NSError *error) {
    }];
}

- (void)contacts:(ABAddressBookRef)addressBook success:(WLSetBlock)success failure:(WLFailureBlock)failure {
    runUnaryQueuedOperation(@"wl_address_book_queue", ^(WLOperation *operation) {
        CFIndex count = ABAddressBookGetPersonCount(addressBook);
        if (count > 0) {
            run_in_default_queue(^{
                CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(addressBook);
                NSMutableSet* contacts = [NSMutableSet set];
                for (CFIndex i = 0; i < count; i++) {
                    WLAddressBookRecord * contact = [WLAddressBookRecord recordWithABRecord:CFArrayGetValueAtIndex(records, i)];
                    if (contact) {
                        [contacts addObject:contact];
                    }
                }
                CFRelease(records);
                NSSet *result = [contacts copy];
                run_in_main_queue(^{
                    if (result.nonempty) {
                        if (success) success(result);
                    } else {
                        if (failure) failure([NSError errorWithDescription:WLLS(@"no_contacts_with_phone_number")]);
                    }
                    [operation finish];
                });
            });
        } else {
            if (failure) failure([NSError errorWithDescription:WLLS(@"no_contacts")]);
            [operation finish];
        }
    });
}

- (void)contacts:(WLSetBlock)success failure:(WLFailureBlock)failure {
	[self addressBook:^(ABAddressBookRef addressBook) {
        [self contacts:addressBook success:success failure:failure];
	} failure:failure];
}

- (void)addressBook:(void (^)(ABAddressBookRef addressBook))success failure:(WLFailureBlock)failure {
    if (sharedAddressBook != NULL) {
        if (success) success(sharedAddressBook);
    } else {
        runUnaryQueuedOperation(@"wl_address_book_queue", ^(WLOperation *operation) {
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                run_in_main_queue(^{
                    if (error) {
                        if (failure) failure((__bridge NSError *)(error));
                    } else if (granted) {
                        sharedAddressBook = addressBook;
                        if (success) success(addressBook);
                    } else {
                        if (failure) failure([NSError errorWithDescription:WLLS(@"no_access_to_contacts")]);
                    }
                    [operation finish];
                });
            });
        });
    }
}

@end
