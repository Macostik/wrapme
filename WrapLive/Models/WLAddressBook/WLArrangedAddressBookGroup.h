//
//  WLArrangedAddressBookGroup.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLAddressBook.h"

typedef BOOL (^WLArrangedAddressBookGroupAddingRule) (WLAddressBookRecord *record);

@interface WLArrangedAddressBookGroup : NSObject

@property (strong, nonatomic) NSMutableArray* records;

@property (strong, nonatomic) WLArrangedAddressBookGroupAddingRule addingRule;

- (instancetype)initWithAddingRule:(WLArrangedAddressBookGroupAddingRule)rule;

- (BOOL)addRecord:(WLAddressBookRecord*)record;

@end
