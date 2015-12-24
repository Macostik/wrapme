//
//  WLArrangedAddressBook.h
//  meWrap
//
//  Created by Ravenpod on 2/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLArrangedAddressBook : NSObject

@property (strong, nonatomic) NSArray *groups;

@property (strong, nonatomic) NSMutableSet *selectedPhoneNumbers;

- (void)addRecords:(NSArray*)records;

- (void)selectPhoneNumber:(AddressBookPhoneNumber*)phoneNumber;

- (AddressBookPhoneNumber*)selectedPhoneNumber:(AddressBookPhoneNumber*)phoneNumber;

- (instancetype)filter:(NSString*)text;

- (AddressBookPhoneNumber*)phoneNumberEqualTo:(AddressBookPhoneNumber*)phoneNumber;

@end
