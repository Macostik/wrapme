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
#import "WLWrap.h"

@implementation WLArrangedAddressBook

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self)weakSelf = self;
        self.groups = [NSArray arrayWithBlock:^(NSMutableArray *array) {
            [array addObject:[[WLArrangedAddressBookGroup alloc] initWithTitle:@"FRIENDS ON WRAPLIVE" addingRule:^BOOL(WLAddressBookRecord *record) {
                WLAddressBookPhoneNumber *phoneNumber = [record.phoneNumbers lastObject];
                if (phoneNumber.user) {
                    if (phoneNumber.activated) {
                        return YES;
                    } else {
                        return [weakSelf.wrap.contributors containsObject:phoneNumber.user];
                    }
                } else {
                    return NO;
                }
            }]];
            [array addObject:[[WLArrangedAddressBookGroup alloc] initWithTitle:@"INVITE TO WRAPLIVE" addingRule:^BOOL(WLAddressBookRecord *record) {
                WLAddressBookPhoneNumber *phoneNumber = [record.phoneNumbers lastObject];
                return phoneNumber.user == nil;
            }]];
            [array addObject:[[WLArrangedAddressBookGroup alloc] initWithTitle:nil addingRule:^BOOL(WLAddressBookRecord *record) {
                WLAddressBookPhoneNumber *phoneNumber = [record.phoneNumbers lastObject];
                return (phoneNumber.user && !phoneNumber.activated && ![weakSelf.wrap.contributors containsObject:phoneNumber.user]);
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
    
    record = [WLAddressBookRecord record:record.phoneNumbers];
    
    if (!record.phoneNumbers.nonempty) {
        
        return [NSError errorWithDescription:WLLS(@"You cannot add yourself.")];
        
    } else if ([record.phoneNumbers count] == 1) {
        
        [self addRecordToGroup:record];
        
    } else {
        
        NSMutableArray *persons = [record.phoneNumbers mutableCopy];
        
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
        } else {
            return [NSError errorWithDescription:WLLS(@"No contact data.")];
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
            WLArrangedAddressBookGroup *_group = [[WLArrangedAddressBookGroup alloc] initWithTitle:group.title addingRule:group.addingRule];
            _group.records = [group.records objectsWhere:@"name contains[c] %@", text];
            return _group;
        }];
        return addressBook;
    } else {
        return self;
    }
}

@end
