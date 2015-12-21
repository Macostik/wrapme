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

@property (weak, nonatomic) Wrap *wrap;

@property (strong, nonatomic) NSArray *groups;

@property (strong, nonatomic) NSMutableSet *selectedPhoneNumbers;

- (instancetype)initWithWrap:(Wrap *)wrap;

- (void)addRecords:(NSSet*)records;

- (void)addRecord:(AddressBookRecord*)record;

- (void)addRecord:(AddressBookRecord*)record success:(WLArrangedAddressBookRecordHandler)success failure:(FailureBlock)failure;

- (WLArrangedAddressBookGroup*)groupWithRecord:(AddressBookRecord*)record;

- (void)selectPhoneNumber:(AddressBookPhoneNumber*)phoneNumber;

- (AddressBookPhoneNumber*)selectedPhoneNumber:(AddressBookPhoneNumber*)phoneNumber;

- (instancetype)filteredAddressBookWithText:(NSString*)text;

- (AddressBookPhoneNumber*)phoneNumberIdenticalTo:(AddressBookPhoneNumber*)phoneNumber;

@end
