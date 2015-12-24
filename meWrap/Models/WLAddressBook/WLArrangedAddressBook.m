//
//  WLArrangedAddressBook.m
//  meWrap
//
//  Created by Ravenpod on 2/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLArrangedAddressBook.h"

@interface WLArrangedAddressBook ()

@end

@implementation WLArrangedAddressBook

- (instancetype)init {
    self = [super init];
    if (self) {
        ArrangedAddressBookGroup *registeredGroup = [[ArrangedAddressBookGroup alloc] initWithTitle:@"friends_on_meWrap".ls registered:YES];
        ArrangedAddressBookGroup *unregisteredGroup = [[ArrangedAddressBookGroup alloc] initWithTitle:@"invite_to_meWrap".ls registered:NO];
        self.groups = @[registeredGroup, unregisteredGroup];
        self.selectedPhoneNumbers = [NSMutableSet set];
    }
    return self;
}

- (void)addRecords:(NSArray *)records {
    for (AddressBookRecord* record in records) {
        [self addRecord:record];
    }
    [self sort];
}

- (void)addRecord:(AddressBookRecord*)record {
    
    record = [[AddressBookRecord alloc] initWithRecord:record];
    
    if (!record.phoneNumbers.nonempty) {
        return;
    } else if ([record.phoneNumbers count] == 1) {
        [self addRecordToGroup:record];
    } else {
        
        NSMutableArray *phoneNumbers = [record.phoneNumbers mutableCopy];
        
        for (AddressBookPhoneNumber *phoneNumber in record.phoneNumbers) {
            if (phoneNumber.user) {
                AddressBookRecord *newRecord = [[AddressBookRecord alloc] initWithPhoneNumbers:@[phoneNumber]];
                if (!phoneNumber.user.name.nonempty) {
                    newRecord.name = record.name;
                }
                [self addRecordToGroup:newRecord];
                [phoneNumbers removeObject:phoneNumber];
            }
        }
        
        if (phoneNumbers.nonempty) {
            record.phoneNumbers = [phoneNumbers copy];
            [self addRecordToGroup:record];
        }
    }
}

- (void)addRecordToGroup:(AddressBookRecord *)record {
    for (ArrangedAddressBookGroup *group in self.groups) {
        if ([group add:record]) {
            break;
        }
    }
}

- (void)sort {
    for (ArrangedAddressBookGroup *group in self.groups) {
        [group sort];
    }
}

- (void)selectPhoneNumber:(AddressBookPhoneNumber *)phoneNumber {
    AddressBookPhoneNumber* _phoneNumber = [self selectedPhoneNumber:phoneNumber];
    if (_phoneNumber) {
        [self.selectedPhoneNumbers removeObject:_phoneNumber];
    } else {
        [self.selectedPhoneNumbers addObject:phoneNumber];
    }
}

- (AddressBookPhoneNumber *)selectedPhoneNumber:(AddressBookPhoneNumber *)phoneNumber {
    for (AddressBookPhoneNumber* _phoneNumber in self.selectedPhoneNumbers) {
        if ([_phoneNumber equals:phoneNumber]) {
            return _phoneNumber;
        }
    }
    return nil;
}

- (instancetype)filter:(NSString *)text {
    if (text.nonempty) {
        WLArrangedAddressBook *addressBook = [[WLArrangedAddressBook alloc] init];
        addressBook.groups = [self.groups map:^id (ArrangedAddressBookGroup *group) {
            return [group filter:text];
        }];
        return addressBook;
    } else {
        return self;
    }
}

- (AddressBookPhoneNumber *)phoneNumberEqualTo:(AddressBookPhoneNumber *)phoneNumber {
    for (ArrangedAddressBookGroup *group in self.groups) {
        AddressBookPhoneNumber *_phoneNumber = [group phoneNumberEqualTo:phoneNumber];
        if (_phoneNumber) {
            return _phoneNumber;
        }
    }
    return nil;
}

@end
