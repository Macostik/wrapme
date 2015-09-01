//
//  WLArrangedAddressBookGroup.m
//  moji
//
//  Created by Ravenpod on 2/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLArrangedAddressBookGroup.h"

@implementation WLArrangedAddressBookGroup

- (instancetype)init {
    self = [super init];
    if (self) {
        self.records = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title addingRule:(WLArrangedAddressBookGroupAddingRule)rule {
    self = [self init];
    if (self) {
        self.title = title;
        self.addingRule = rule;
    }
    return self;
}

- (BOOL)addRecord:(WLAddressBookRecord *)record {
    if (self.addingRule && self.addingRule(record)) {
        [self.records addObject:record];
        return YES;
    } else {
        return NO;
    }
}

- (void)sortByPriorityName {
    NSComparator comparator = ^NSComparisonResult(WLAddressBookRecord* contact1, WLAddressBookRecord* contact2) {
        WLAddressBookPhoneNumber *phoneNumber1 =  [contact1.phoneNumbers lastObject];
        WLAddressBookPhoneNumber *phoneNumber2 =  [contact2.phoneNumbers lastObject];
        return [[phoneNumber1 priorityName] compare:[phoneNumber2 priorityName]];
    };
 
    [self.records sortUsingComparator:comparator];
}

@end
