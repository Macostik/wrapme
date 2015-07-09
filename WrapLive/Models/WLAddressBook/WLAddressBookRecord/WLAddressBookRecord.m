//
//  WLAddressBookRecord.m
//  WrapLive
//
//  Created by Sergey Maximenko on 2/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAddressBookRecord.h"
#import <objc/runtime.h>
#import "NSObject+AssociatedObjects.h"
#import "WLAddressBookPhoneNumber.h"

@implementation WLAddressBookRecord

+ (void)record:(ABRecordRef)record completion:(WLContactBlock)completion {
    NSArray* phones = WLAddressBookGetPhones(record);
    if (phones.nonempty) {
        WLAddressBookRecord* contact = [WLAddressBookRecord new];
        contact.name = WLAddressBookGetName(record);
        contact.phoneNumbers = phones;
        [contact.phoneNumbers makeObjectsPerformSelector:@selector(setName:) withObject:contact.name];
        if (ABPersonHasImageData(record)) {
            NSString* identifier = [NSString stringWithFormat:@"addressbook_%d", ABRecordGetRecordID(record)];
            WLStringBlock complete = ^(NSString* path) {
                WLPicture* picture = [WLPicture new];
                picture.large = path;
                picture.medium = path;
                picture.small = path;
                [contact.phoneNumbers makeObjectsPerformSelector:@selector(setPicture:) withObject:picture];
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
    NSMutableArray* WLAddressBookPhoneNumbers = [NSMutableArray array];
    ABMultiValueRef phones = ABRecordCopyValue(record,kABPersonPhoneProperty);
    CFIndex count = ABMultiValueGetCount(phones);
    for (CFIndex index = 0; index < count; ++index) {
        WLAddressBookPhoneNumber* person = [[WLAddressBookPhoneNumber alloc] init];
        person.phone = phoneNumberClearing((__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phones, index));
        if (person.phone.length >= WLAddressBookPhoneNumberMinimumLength) {
            CFStringRef phoneLabel = ABMultiValueCopyLabelAtIndex(phones, index);
            person.phone.label = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(phoneLabel);
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

+ (instancetype)record:(NSArray *)phoneNumbers {
    WLAddressBookRecord *record = [[WLAddressBookRecord alloc] init];
    record.phoneNumbers = phoneNumbers;
    return record;
}

- (void)setPhoneNumbers:(NSArray *)phoneNumbers {
    _phoneNumbers = phoneNumbers;
    [phoneNumbers makeObjectsPerformSelector:@selector(setRecord:) withObject:self];
}

- (NSString *)name {
    if (!_name.nonempty) {
        _name = [[self.phoneNumbers select:^BOOL(WLAddressBookPhoneNumber* person) {
            return person.user.name.nonempty;
        }] name];
    }
    if (!_name.nonempty) {
        _name = [[self.phoneNumbers select:^BOOL(WLAddressBookPhoneNumber* person) {
            return person.phone.nonempty;
        }] phone];
    }
    return _name;
}

- (BOOL)registered {
    WLAddressBookPhoneNumber *phoneNumber = [self.phoneNumbers lastObject];
    return phoneNumber.user != nil;
}

- (NSString *)priorityName {
    WLAddressBookPhoneNumber *phoneNumber = [self.phoneNumbers lastObject];
    return phoneNumber.priorityName;
}

- (WLPicture *)priorityPicture {
    WLAddressBookPhoneNumber *phoneNumber = [self.phoneNumbers lastObject];
    return phoneNumber.priorityPicture;
}

@end
