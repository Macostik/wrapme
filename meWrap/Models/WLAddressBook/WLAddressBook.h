//
//  WLAddressBook.h
//  meWrap
//
//  Created by Ravenpod on 25.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLAddressBookRecord.h"
#import "WLAddressBookPhoneNumber.h"

@class WLAddressBook;

@protocol WLAddressBookReceiver <NSObject>

@optional
- (void)addressBook:(WLAddressBook*)addressBook didUpdateCachedRecords:(NSSet*)cachedRecords;

@end


@interface WLAddressBook : WLBroadcaster {
@public ABAddressBookRef sharedAddressBook;
}

+ (instancetype)addressBook;

- (BOOL)cachedRecords:(SetBlock)success failure:(FailureBlock)failure;

- (void)records:(SetBlock)success failure:(FailureBlock)failure;

- (void)beginCaching;

- (void)endCaching;

- (void)updateCachedRecords;

- (void)updateCachedRecordsAfterFailure;

- (void)contacts:(SetBlock)success failure:(FailureBlock)failure;

@end