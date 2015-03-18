//
//  WLArrangedAddressBook.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLAddressBook.h"
#import "WLArrangedAddressBookGroup.h"

@class WLWrap;

typedef void (^WLArrangedAddressBookRecordHandler)(BOOL exists, WLAddressBookRecord *record, WLArrangedAddressBookGroup *group);

@interface WLArrangedAddressBook : NSObject

@property (strong, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) NSArray *groups;

@property (strong, nonatomic) NSMutableArray *selectedPhoneNumbers;

- (instancetype)initWithWrap:(WLWrap*)wrap;

- (void)addRecords:(NSArray*)records;

- (NSError *)addRecord:(WLAddressBookRecord*)record;

- (NSError *)addUniqueRecord:(WLAddressBookRecord*)record completion:(WLArrangedAddressBookRecordHandler)completion;

- (WLArrangedAddressBookGroup*)groupWithRecord:(WLAddressBookRecord*)record;

- (void)selectPhoneNumber:(WLAddressBookPhoneNumber*)phoneNumber;

- (WLAddressBookPhoneNumber*)selectedPhoneNumber:(WLAddressBookPhoneNumber*)phoneNumber;

- (instancetype)filteredAddressBookWithText:(NSString*)text;

- (WLAddressBookPhoneNumber*)phoneNumberIdenticalTo:(WLAddressBookPhoneNumber*)phoneNumber;

@end
