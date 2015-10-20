//
//  WLAddressBookRecord.m
//  meWrap
//
//  Created by Ravenpod on 2/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAddressBookRecord.h"
#import <objc/runtime.h>
#import "NSObject+AssociatedObjects.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAddressBook.h"

@implementation WLAddressBookRecord

+ (instancetype)recordWithABRecord:(ABRecordRef)record {
    NSArray* phones = WLAddressBookGetPhones(record);
    if (phones.nonempty) {
        WLAddressBookRecord* contact = [WLAddressBookRecord new];
        contact.hasImage = ABPersonHasImageData(record);
        contact.recordID = ABRecordGetRecordID(record);
        contact.name = WLAddressBookGetName(record);
        contact.phoneNumbers = phones;
        return contact;
    }
    return nil;
}

+ (instancetype)recordWithNumbers:(NSArray *)phoneNumbers {
    WLAddressBookRecord *record = [[WLAddressBookRecord alloc] init];
    record.phoneNumbers = phoneNumbers;
    return record;
}

+ (instancetype)recordWithRecord:(WLAddressBookRecord *)record {
    WLAddressBookRecord *_record = [[WLAddressBookRecord alloc] init];
    _record.hasImage = record.hasImage;
    _record.recordID = record.recordID;
    _record.name = record.name;
    _record.picture = record->_picture;
    _record.phoneNumbers = record.phoneNumbers;
    return _record;
}

static inline NSArray* WLAddressBookGetPhones(ABRecordRef record) {
    NSMutableArray* WLAddressBookPhoneNumbers = [NSMutableArray array];
    ABMultiValueRef phones = ABRecordCopyValue(record,kABPersonPhoneProperty);
    CFIndex count = ABMultiValueGetCount(phones);
    for (CFIndex index = 0; index < count; ++index) {
        WLAddressBookPhoneNumber* person = [[WLAddressBookPhoneNumber alloc] init];
        person.phone = phoneNumberClearing((__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phones, index));
        if (person.phone.length >= WLAddressBookPhoneNumberMinimumLength) {
            CFStringRef phoneLabel = ABMultiValueCopyLabelAtIndex(phones, index);
            person.label = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(phoneLabel);
            if (phoneLabel != NULL) {
                CFRelease(phoneLabel);
            }
            [WLAddressBookPhoneNumbers addObject:person];
        }
    }
    if (phones != NULL) {
        CFRelease(phones);
    }
    return [WLAddressBookPhoneNumbers copy];
}

static inline NSString* WLAddressBookGetName(ABRecordRef record) {
    NSString* firstName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    NSString* lastName  = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    return [[NSString stringWithFormat:@"%@ %@",WLString(firstName),WLString(lastName)] trim];
}

static inline NSData* WLAddressBookGetImage(ABRecordRef record) {
    return (__bridge_transfer NSData *)ABPersonCopyImageData(record);
}

- (void)setPhoneNumbers:(NSArray *)phoneNumbers {
    _phoneNumbers = phoneNumbers;
    [phoneNumbers makeObjectsPerformSelector:@selector(setRecord:) withObject:self];
}

- (WLAsset *)picture {
    if (!_picture) {
        if (self.recordID && self.hasImage && [WLAddressBook addressBook]->sharedAddressBook != NULL) {
            ABRecordRef record = ABAddressBookGetPersonWithRecordID([WLAddressBook addressBook]->sharedAddressBook, self.recordID);
            NSString* identifier = [NSString stringWithFormat:@"addressbook_%d", self.recordID];
            NSString *path = [[WLImageCache cache] pathWithIdentifier:identifier];
            if (![[WLImageCache cache] containsObjectWithIdentifier:identifier]) {
                NSData* imageData = WLAddressBookGetImage(record);
                if (imageData) {
                    [[WLImageCache cache] setImageData:imageData withIdentifier:identifier];
                }
            }
            WLAsset* picture = [WLAsset new];
            picture.large = picture.medium = picture.small = path;
            _picture = picture;
        }
    }
    return _picture;
}

- (BOOL)registered {
    WLAddressBookPhoneNumber *phoneNumber = [self.phoneNumbers lastObject];
    return phoneNumber.user != nil;
}

- (NSString *)phoneStrings {
    WLAddressBookPhoneNumber *person = [self.phoneNumbers lastObject];
    if (person) {
        WLUser *user = person.user;
        if (user.valid) {
            return [user phones];
        } else {
            return [person phone];
        }
    }
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", self.name, self.phoneNumbers.description];
}

@end
