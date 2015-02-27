//
//  WLArrangedAddressBook.m
//  WrapLive
//
//  Created by Sergey Maximenko on 2/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLArrangedAddressBook.h"
#import "NSError+WLAPIManager.h"
#import "NSString+Additions.h"
#import "NSArray+Additions.h"
#import "WLUser+Extended.h"
#import "WLArrangedAddressBookGroup.h"

@implementation WLArrangedAddressBook

- (instancetype)init {
    self = [super init];
    if (self) {
        self.groups = [NSArray arrayWithBlock:^(NSMutableArray *array) {
            [array addObject:[[WLArrangedAddressBookGroup alloc] initWithAddingRule:^BOOL(WLAddressBookRecord *record) {
                return record.registered;
            }]];
            [array addObject:[[WLArrangedAddressBookGroup alloc] initWithAddingRule:^BOOL(WLAddressBookRecord *record) {
                return !record.registered;
            }]];
//            [array addObject:[[WLArrangedAddressBookGroup alloc] initWithAddingRule:^BOOL(WLAddressBookRecord *record) {
//                
//            }]];
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
        [self baseAddRecord:record];
    }
    [self sort];
}

- (NSError *)addRecord:(WLAddressBookRecord *)record {
    NSError *error = [self baseAddRecord:record];
    if (!error) [self sort];
    return error;
}

- (NSError *)baseAddRecord:(WLAddressBookRecord*)record {
    NSMutableArray *persons = [record.phoneNumbers mutableCopy];
    
    if (!persons.nonempty) {
        return [NSError errorWithDescription:WLLS(@"No contact data.")];
    }
    
    [self removeCurrentUser:persons];
    
    if (!persons.nonempty) {
        return [NSError errorWithDescription:WLLS(@"You cannot add yourself.")];
    } else if ([persons count] == 1) {
        record.phoneNumbers = [persons copy];
        [self addRecordToGroup:record];
    } else {
        [persons removeObjectsWhileEnumerating:^BOOL(WLAddressBookPhoneNumber *person) {
            if (person.user) {
                [self addRecordToGroup:[WLAddressBookRecord record:@[person]]];
                return YES;
            }
            return NO;
        }];
        if (persons.nonempty) {
            record.phoneNumbers = [persons copy];
            [self addRecordToGroup:record];
        }
    }
    
    return nil;
}

- (void)addRecordToGroup:(WLAddressBookRecord *)record {
    for (WLArrangedAddressBookGroup *group in self.groups) {
        if ([group addRecord:record]) break;
    }
}

- (void)sort {
    NSComparator comparator = ^NSComparisonResult(WLAddressBookRecord* contact1, WLAddressBookRecord* contact2) {
        return [[contact1 name] compare:[contact2 name]];
    };
    for (WLArrangedAddressBookGroup *group in self.groups) {
        [group.records sortUsingComparator:comparator];
    }
}

- (void)removeCurrentUser:(NSMutableArray *)persons {
    [persons removeObjectsWhileEnumerating:^BOOL(WLAddressBookPhoneNumber *person) {
        if (person.user && [person.user isCurrentUser]) {
            return YES;
        }
        return NO;
    }];
}

- (NSError *)addUniqueRecord:(WLAddressBookRecord *)record completion:(WLArrangedAddressBookRecordHandler)completion {
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
        WLAddressBookRecord *record = [group.records selectObject:selectBlock];
        if (record) {
            if (completion) completion(record, group);
            return nil;
        }
    }
    NSError *error = [self addRecord:record];
    if (!error && completion) {
        completion(record, [self groupWithRecord:record]);
    }
    return error;
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
            WLArrangedAddressBookGroup *_group = [[WLArrangedAddressBookGroup alloc] initWithAddingRule:group.addingRule];
            _group.records = [group.records objectsWhere:@"name contains[c] %@", text];
            return _group;
        }];
        return addressBook;
    } else {
        return self;
    }
}

@end
