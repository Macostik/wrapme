//
//  WLArrangedAddressBook.h
//  meWrap
//
//  Created by Ravenpod on 2/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLAddressBook.h"
#import "WLArrangedAddressBookGroup.h"

typedef void (^WLArrangedAddressBookRecordHandler)(NSArray *records, NSArray *groups);
typedef void (^WLArrangedAddressBookUniqueRecordHandler)(BOOL exists, NSArray *records, NSArray *groups);

@interface WLArrangedAddressBook : NSObject

@property (weak, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) NSArray *groups;

@property (strong, nonatomic) NSMutableArray *selectedPhoneNumbers;

- (instancetype)initWithWrap:(WLWrap*)wrap;

- (void)addRecords:(NSArray*)records;

- (void)addRecord:(WLAddressBookRecord*)record;

- (void)addRecord:(WLAddressBookRecord*)record success:(WLArrangedAddressBookRecordHandler)success failure:(WLFailureBlock)failure;

- (void)addUniqueRecord:(WLAddressBookRecord*)record success:(WLArrangedAddressBookUniqueRecordHandler)success failure:(WLFailureBlock)failure;

- (WLArrangedAddressBookGroup*)groupWithRecord:(WLAddressBookRecord*)record;

- (void)selectPhoneNumber:(WLAddressBookPhoneNumber*)phoneNumber;

- (WLAddressBookPhoneNumber*)selectedPhoneNumber:(WLAddressBookPhoneNumber*)phoneNumber;

- (instancetype)filteredAddressBookWithText:(NSString*)text;

- (WLAddressBookPhoneNumber*)phoneNumberIdenticalTo:(WLAddressBookPhoneNumber*)phoneNumber;

@end
