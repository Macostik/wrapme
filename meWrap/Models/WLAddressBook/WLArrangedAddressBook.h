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

- (void)addRecord:(WLAddressBookRecord*)record;

- (void)addRecord:(WLAddressBookRecord*)record success:(WLArrangedAddressBookRecordHandler)success failure:(FailureBlock)failure;

- (WLArrangedAddressBookGroup*)groupWithRecord:(WLAddressBookRecord*)record;

- (void)selectPhoneNumber:(WLAddressBookPhoneNumber*)phoneNumber;

- (WLAddressBookPhoneNumber*)selectedPhoneNumber:(WLAddressBookPhoneNumber*)phoneNumber;

- (instancetype)filteredAddressBookWithText:(NSString*)text;

- (WLAddressBookPhoneNumber*)phoneNumberIdenticalTo:(WLAddressBookPhoneNumber*)phoneNumber;

@end
