//
//  WLArrangedAddressBook.m
//  moji
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
        self.groups = [[NSArray array] mutate:^(NSMutableArray *array) {
            [array addObject:[[WLArrangedAddressBookGroup alloc] initWithTitle:WLLS(@"friends_on_16wrap") addingRule:^BOOL(WLAddressBookRecord *record) {
                WLAddressBookPhoneNumber *phoneNumber = [record.phoneNumbers lastObject];
                return phoneNumber.user != nil;
            }]];
            [array addObject:[[WLArrangedAddressBookGroup alloc] initWithTitle:WLLS(@"invite_to_16wrap") addingRule:^BOOL(WLAddressBookRecord *record) {
                WLAddressBookPhoneNumber *phoneNumber = [record.phoneNumbers lastObject];
                return phoneNumber.user == nil;
            }]];
        }];
        self.selectedPhoneNumbers = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithWrap:(WLWrap *)wrap {
    self = [self init];
    if (self) {
        self.wrap = wrap;
    }
    return self;
}

- (void)addRecords:(NSArray *)records {
    for (WLAddressBookRecord* record in records) {
        [self baseAddRecord:record success:nil failure:nil];
    }
    [self sort];
}

- (void)addRecord:(WLAddressBookRecord *)record {
    [self addRecord:record success:nil failure:nil];
}

- (void)addRecord:(WLAddressBookRecord *)record success:(WLArrangedAddressBookRecordHandler)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self baseAddRecord:record success:^( NSArray *records, NSArray *groups) {
        [weakSelf sort];
        if (success) success(records, groups);
    } failure:failure];
}

- (void)baseAddRecord:(WLAddressBookRecord*)record success:(WLArrangedAddressBookRecordHandler)success failure:(WLFailureBlock)failure {
    
    record = [WLAddressBookRecord record:record.phoneNumbers];
    
    if (!record.phoneNumbers.nonempty) {
        
        if (failure) failure(WLError(WLLS(@"cannot_add_yourself")));
        
    } else if ([record.phoneNumbers count] == 1) {
        
        WLArrangedAddressBookGroup *group = [self addRecordToGroup:record];
        
        if (success) success(@[record], group ? @[group] : nil);
        
    } else {
        
        NSMutableArray *groups = [NSMutableArray array];
        NSMutableArray *records = [NSMutableArray array];
        NSMutableArray *phoneNumbers = [record.phoneNumbers mutableCopy];
        
        [phoneNumbers removeSelectively:^BOOL(WLAddressBookPhoneNumber *phoneNumber) {
            if (phoneNumber.user) {
                WLAddressBookRecord *newRecord = [WLAddressBookRecord record:@[phoneNumber]];
                WLArrangedAddressBookGroup *group = [self addRecordToGroup:newRecord];
                if (group) {
                    [groups addObject:group];
                    [records addObject:newRecord];
                }
                return YES;
            }
            return NO;
        }];
        
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

- (WLArrangedAddressBookGroup*)addRecordToGroup:(WLAddressBookRecord *)record {
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

- (void)addUniqueRecord:(WLAddressBookRecord *)record success:(WLArrangedAddressBookUniqueRecordHandler)success failure:(WLFailureBlock)failure {
    WLAddressBookPhoneNumber *person = [record.phoneNumbers lastObject];
    SelectBlock selectBlock = ^BOOL(WLAddressBookRecord* item) {
        for (WLAddressBookPhoneNumber* _person in item.phoneNumbers) {
            if ([_person isEqualToPerson:person]) {
                person.name = item.name;
                return YES;
            }
        }
        return NO;
    };
    for (WLArrangedAddressBookGroup *group in self.groups) {
        WLAddressBookRecord *record = [group.records select:selectBlock];
        if (record) {
            if (success) success(YES, @[record], @[group]);
            return;
        }
    }
    [self addRecord:record success:^(NSArray *records, NSArray *groups) {
        if (success) success(NO, records, groups);
    } failure:failure];
}

- (WLArrangedAddressBookGroup *)groupWithRecord:(WLAddressBookRecord *)record {
    for (WLArrangedAddressBookGroup *group in self.groups) {
        if ([group.records containsObject:record]) return group;
    }
    return nil;
}

- (void)selectPhoneNumber:(WLAddressBookPhoneNumber *)phoneNumber {
    WLAddressBookPhoneNumber* _phoneNumber = [self selectedPhoneNumber:phoneNumber];
    if (_phoneNumber) {
        [self.selectedPhoneNumbers removeObject:_phoneNumber];
    } else {
        [self.selectedPhoneNumbers addObject:phoneNumber];
    }
}

- (WLAddressBookPhoneNumber *)selectedPhoneNumber:(WLAddressBookPhoneNumber *)phoneNumber {
    for (WLAddressBookPhoneNumber* _phoneNumber in self.selectedPhoneNumbers) {
        if ([_phoneNumber isEqualToPerson:phoneNumber]) {
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
            _group.records = [group.records selects:^BOOL(WLAddressBookRecord  *record) {
                WLAddressBookPhoneNumber *phoneNumbler = record.phoneNumbers.lastObject;
                return ([phoneNumbler.priorityName rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound);
            }];
            return _group;
        }];
        return addressBook;
    } else {
        return self;
    }
}

- (WLAddressBookPhoneNumber *)phoneNumberIdenticalTo:(WLAddressBookPhoneNumber *)phoneNumber {
    for (WLArrangedAddressBookGroup *group in self.groups) {
        for (WLAddressBookRecord *record in group.records) {
            for (WLAddressBookPhoneNumber *_phoneNumber in record.phoneNumbers) {
                if ([_phoneNumber isEqualToPerson:phoneNumber]) {
                    return _phoneNumber;
                }
            }
        }
    }
    return nil;
}

@end
