//
//  WLAddressBookRecord.h
//  meWrap
//
//  Created by Ravenpod on 2/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface WLAddressBookRecord : NSObject

@property (nonatomic) ABRecordID recordID;

@property (nonatomic) BOOL hasImage;

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) NSArray *phoneNumbers;

@property (nonatomic, readonly) BOOL registered;

@property (strong, nonatomic) Asset* picture;

@property (readonly, nonatomic) NSString *phoneStrings;

+ (instancetype)recordWithABRecord:(ABRecordRef)record;

+ (instancetype)recordWithNumbers:(NSArray*)phoneNumbers;

+ (instancetype)recordWithRecord:(WLAddressBookRecord *)record;

@end
