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
- (void)addressBook:(WLAddressBook*)addressBook didUpdateCachedRecords:(NSArray*)cachedRecords;

@end


@interface WLAddressBook : WLBroadcaster {
@public ABAddressBookRef sharedAddressBook;
}

+ (instancetype)addressBook;

- (BOOL)cachedRecords:(ArrayBlock)success failure:(FailureBlock)failure;

- (void)records:(ArrayBlock)success failure:(FailureBlock)failure;

- (void)beginCaching;

- (void)endCaching;

- (void)updateCachedRecords;

- (void)updateCachedRecordsAfterFailure;

- (void)contacts:(ArrayBlock)success failure:(FailureBlock)failure;

@end