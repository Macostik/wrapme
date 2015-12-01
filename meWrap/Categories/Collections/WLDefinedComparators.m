//
//  WLDefinedComparators.m
//  meWrap
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDefinedComparators.h"

NSComparator defaultComparator = ^NSComparisonResult(id obj1, id obj2) {
    return [obj1 compare:obj2];
};

NSComparator comparatorByUpdatedAt = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj1 updatedAt] compare:[obj2 updatedAt]];
};

NSComparator comparatorByCreatedAt = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj1 createdAt] compare:[obj2 createdAt]];
};

NSComparator comparatorByCreatedAtTimestamp = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj1 createdAt] timestampCompare:[obj2 createdAt]];
};

NSComparator comparatorByDate = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj1 date] compare:[obj2 date]];
};

NSComparator comparatorByName = ^NSComparisonResult(id obj1, id obj2) {
    return [[obj2 name] compare:[obj1 name] options:NSCaseInsensitiveSearch];
};
