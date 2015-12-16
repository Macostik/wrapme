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
#import "WLAddressBookPhoneNumber.h"
#import "WLAddressBookRecord.h"

@interface WLAddressBook ()

@property (strong, nonatomic) NSArray *cachedRecords;

@property (strong, nonatomic) RunQueue *runQueue;

@end

@implementation WLAddressBook

+ (instancetype)addressBook {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (RunQueue *)runQueue {
    if (_runQueue == nil) {
        _runQueue = [[RunQueue alloc] initWithLimit:1];
    }
    return _runQueue;
}

- (void)setCachedRecords:(NSArray *)cachedRecords {
    _cachedRecords = cachedRecords;
    for (id receiver in [self broadcastReceivers]) {
        if ([receiver respondsToSelector:@selector(addressBook:didUpdateCachedRecords:)]) {
            [receiver addressBook:self didUpdateCachedRecords:cachedRecords];
        }
    }
}

- (BOOL)cachedRecords:(ArrayBlock)success failure:(FailureBlock)failure {
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

- (void)records:(ArrayBlock)success failure:(FailureBlock)failure {
    [self addressBook:^(ABAddressBookRef addressBook) {
        [self records:addressBook success:success failure:failure];
    } failure:failure];
}

- (void)records:(ABAddressBookRef)addressBook success:(ArrayBlock)success failure:(FailureBlock)failure {
    [self contacts:addressBook success:^(NSArray *array) {
        [self.runQueue run:^(Block finish) {
            [[WLAPIRequest contributorsFromContacts:array] send:^(id object) {
                self.cachedRecords = object;
                if (success) success(object);
                finish();
            } failure:^(NSError *error) {
                if (failure) failure(error);
                finish();
            }];
        }];
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
        [self records:addressBook success:^(NSArray *array) {
            updateCachedRecordsFailed = NO;
        } failure:^(NSError *error) {
            updateCachedRecordsFailed = YES;
        }];
    } failure:nil];
}

void addressBookChanged (ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    [WLAddressBook addressBook]->sharedAddressBook = addressBook;
    [[WLAddressBook addressBook] enqueueSelector:@selector(updateCachedRecords) delay:.0f];
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

- (void)contacts:(ABAddressBookRef)addressBook success:(ArrayBlock)success failure:(FailureBlock)failure {
    [self.runQueue run:^(Block finish) {
        CFIndex count = ABAddressBookGetPersonCount(addressBook);
        if (count > 0) {
            [[DispatchQueue defaultQueue] run:^{
                CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(addressBook);
                NSMutableArray* contacts = [NSMutableArray array];
                for (CFIndex i = 0; i < count; i++) {
                    WLAddressBookRecord * contact = [WLAddressBookRecord recordWithABRecord:CFArrayGetValueAtIndex(records, i)];
                    if (contact) {
                        [contacts addObject:contact];
                    }
                }
                CFRelease(records);
                NSArray *result = [contacts copy];
                [[DispatchQueue mainQueue] run:^{
                    if (result.nonempty) {
                        if (success) success(result);
                    } else {
                        if (failure) failure([[NSError alloc] initWithMessage:@"no_contacts_with_phone_number".ls]);
                    }
                    finish();
                }];
            }];
        } else {
            if (failure) failure([[NSError alloc] initWithMessage:@"no_contacts".ls]);
            finish();
        }
    }];
}

- (void)contacts:(ArrayBlock)success failure:(FailureBlock)failure {
	[self addressBook:^(ABAddressBookRef addressBook) {
        [self contacts:addressBook success:success failure:failure];
	} failure:failure];
}

- (void)addressBook:(void (^)(ABAddressBookRef addressBook))success failure:(FailureBlock)failure {
    if (sharedAddressBook != NULL) {
        if (success) success(sharedAddressBook);
    } else {
        [self.runQueue run:^(Block finish) {
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                [[DispatchQueue mainQueue] run:^{
                    if (error) {
                        if (failure) failure((__bridge NSError *)(error));
                    } else if (granted) {
                        sharedAddressBook = addressBook;
                        if (success) success(addressBook);
                    } else {
                        if (failure) failure([[NSError alloc] initWithMessage:@"no_access_to_contacts".ls]);
                    }
                    finish();
                }];
            });
        }];
    }
}

@end
