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
        self.groups = [[NSArray array] mutate:^(NSMutableArray *array) {
            [array addObject:[[WLArrangedAddressBookGroup alloc] initWithTitle:@"friends_on_meWrap".ls addingRule:^BOOL(WLAddressBookRecord *record) {
                WLAddressBookPhoneNumber *phoneNumber = [record.phoneNumbers lastObject];
                return phoneNumber.user != nil;
            }]];
            [array addObject:[[WLArrangedAddressBookGroup alloc] initWithTitle:@"invite_to_meWrap".ls addingRule:^BOOL(WLAddressBookRecord *record) {
                WLAddressBookPhoneNumber *phoneNumber = [record.phoneNumbers lastObject];
                return phoneNumber.user == nil;
            }]];
        }];
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
    
    record = [WLAddressBookRecord recordWithRecord:record];
    
    if (!record.phoneNumbers.nonempty) {
        
        if (failure) failure([[NSError alloc] initWithMessage:@"cannot_add_yourself".ls]);
        
    } else if ([record.phoneNumbers count] == 1) {
        
        WLArrangedAddressBookGroup *group = [self addRecordToGroup:record];
        
        if (success) success(@[record], group ? @[group] : nil);
        
    } else {
        
        NSMutableArray *groups = [NSMutableArray array];
        NSMutableArray *records = [NSMutableArray array];
        NSMutableArray *phoneNumbers = [record.phoneNumbers mutableCopy];
        
        [phoneNumbers removeSelectively:^BOOL(WLAddressBookPhoneNumber *phoneNumber) {
            if (phoneNumber.user) {
                WLAddressBookRecord *newRecord = [WLAddressBookRecord recordWithNumbers:@[phoneNumber]];
                if (!phoneNumber.user.name.nonempty) {
                    newRecord.name = record.name;
                }
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
            _group.records = [group.records selects:^BOOL(WLAddressBookRecord  *record) {
                WLAddressBookPhoneNumber *phoneNumbler = record.phoneNumbers.lastObject;
                return ([phoneNumbler.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound);
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
                if ([_phoneNumber isEqualToPhoneNumber:phoneNumber]) {
                    return _phoneNumber;
                }
            }
        }
    }
    return nil;
}

@end
