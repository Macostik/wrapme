//
//  WLArrangedAddressBook.m
//  meWrap
//
//  Created by Ravenpod on 2/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLArrangedAddressBook.h"
#import "WLArrangedAddressBookGroup.h"

@implementation WLArrangedAddressBook

- (instancetype)init {
    self = [super init];
    if (self) {
        self.groups = [NSArray arrayWithObjects:[[WLArrangedAddressBookGroup alloc] initWithTitle:@"friends_on_meWrap".ls addingRule:^BOOL(AddressBookRecord *record) {
            AddressBookPhoneNumber *phoneNumber = [record.phoneNumbers lastObject];
            return phoneNumber.user != nil;
        }],[[WLArrangedAddressBookGroup alloc] initWithTitle:@"invite_to_meWrap".ls addingRule:^BOOL(AddressBookRecord *record) {
            AddressBookPhoneNumber *phoneNumber = [record.phoneNumbers lastObject];
            return phoneNumber.user == nil;
        }], nil];
        self.selectedPhoneNumbers = [NSMutableSet set];
    }
    return self;
}

- (instancetype)initWithWrap:(Wrap *)wrap {
    self = [self init];
    if (self) {
        self.wrap = wrap;
    }
    return self;
}

- (void)addRecords:(NSSet *)records {
    for (AddressBookRecord* record in records) {
        [self baseAddRecord:record success:nil failure:nil];
    }
    [self sort];
}

- (void)addRecord:(AddressBookRecord *)record {
    [self addRecord:record success:nil failure:nil];
}

- (void)addRecord:(AddressBookRecord *)record success:(WLArrangedAddressBookRecordHandler)success failure:(FailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self baseAddRecord:record success:^( NSArray *records, NSArray *groups) {
        [weakSelf sort];
        if (success) success(records, groups);
    } failure:failure];
}

- (void)baseAddRecord:(AddressBookRecord*)record success:(WLArrangedAddressBookRecordHandler)success failure:(FailureBlock)failure {
    
    record = [[AddressBookRecord alloc] initWithRecord:record];
    
    if (!record.phoneNumbers.nonempty) {
        
        if (failure) failure([[NSError alloc] initWithMessage:@"cannot_add_yourself".ls]);
        
    } else if ([record.phoneNumbers count] == 1) {
        
        WLArrangedAddressBookGroup *group = [self addRecordToGroup:record];
        
        if (success) success(@[record], group ? @[group] : nil);
        
    } else {
        
        NSMutableArray *groups = [NSMutableArray array];
        NSMutableArray *records = [NSMutableArray array];
        NSMutableArray *phoneNumbers = [record.phoneNumbers mutableCopy];
        
        NSMutableArray *removedPhoneNumbers = [NSMutableArray array];
        
        for (AddressBookPhoneNumber *phoneNumber in phoneNumbers) {
            if (phoneNumber.user) {
                AddressBookRecord *newRecord = [[AddressBookRecord alloc] initWithPhoneNumbers:@[phoneNumber]];
                if (!phoneNumber.user.name.nonempty) {
                    newRecord.name = record.name;
                }
                WLArrangedAddressBookGroup *group = [self addRecordToGroup:newRecord];
                if (group) {
                    [groups addObject:group];
                    [records addObject:newRecord];
                }
                [removedPhoneNumbers addObject:phoneNumber];
            }
        }
        
        [phoneNumbers removeObjectsInArray:removedPhoneNumbers];
        
        if (phoneNumbers.nonempty) {
            record.phoneNumbers = [phoneNumbers copy];
            WLArrangedAddressBookGroup *group = [self addRecordToGroup:record];
            if (group) {
                [groups addObject:group];
                [records addObject:record];
            }
        }
        
        if (success) success(records, groups);
    }
}

- (WLArrangedAddressBookGroup*)addRecordToGroup:(AddressBookRecord *)record {
    for (WLArrangedAddressBookGroup *group in self.groups) {
        if ([group addRecord:record]) {
            return group;
        }
    }
    return nil;
}

- (void)sort {
    for (WLArrangedAddressBookGroup *group in self.groups) {
        [group sortByPriorityName];
    }
}

- (WLArrangedAddressBookGroup *)groupWithRecord:(AddressBookRecord *)record {
    for (WLArrangedAddressBookGroup *group in self.groups) {
        if ([group.records containsObject:record]) return group;
    }
    return nil;
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
        if ([_phoneNumber isEqualToPhoneNumber:phoneNumber]) {
            return _phoneNumber;
        }
    }
    return nil;
}

- (instancetype)filteredAddressBookWithText:(NSString *)text {
    if (text.nonempty) {
        WLArrangedAddressBook *addressBook = [[WLArrangedAddressBook alloc] init];
        addressBook.groups = [self.groups map:^id (WLArrangedAddressBookGroup *group) {
            WLArrangedAddressBookGroup *_group = [[WLArrangedAddressBookGroup alloc] initWithTitle:group.title
                                                                                        addingRule:group.addingRule];
            NSMutableArray *records = [NSMutableArray array];
            for (AddressBookRecord  *record in group.records) {
                AddressBookPhoneNumber *phoneNumbler = record.phoneNumbers.lastObject;
                if ([phoneNumbler.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    [records addObject:record];
                }
            }
            _group.records = [records copy];
            return _group;
        }];
        return addressBook;
    } else {
        return self;
    }
}

- (AddressBookPhoneNumber *)phoneNumberIdenticalTo:(AddressBookPhoneNumber *)phoneNumber {
    for (WLArrangedAddressBookGroup *group in self.groups) {
        for (AddressBookRecord *record in group.records) {
            for (AddressBookPhoneNumber *_phoneNumber in record.phoneNumbers) {
                if ([_phoneNumber isEqualToPhoneNumber:phoneNumber]) {
                    return _phoneNumber;
                }
            }
        }
    }
    return nil;
}

@end
