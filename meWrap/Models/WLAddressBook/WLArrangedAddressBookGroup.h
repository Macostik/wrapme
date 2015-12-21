//
//  WLArrangedAddressBookGroup.h
//  meWrap
//
//  Created by Ravenpod on 2/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLAddressBook.h"

typedef BOOL (^WLArrangedAddressBookGroupAddingRule) (AddressBookRecord *record);

@interface WLArrangedAddressBookGroup : NSObject

@property (strong, nonatomic) NSString *title;

@property (strong, nonatomic) NSMutableArray* records;

@property (strong, nonatomic) WLArrangedAddressBookGroupAddingRule addingRule;

- (instancetype)initWithTitle:(NSString*)title addingRule:(WLArrangedAddressBookGroupAddingRule)rule;

- (BOOL)addRecord:(AddressBookRecord*)record;

- (void)sortByPriorityName;

@end
