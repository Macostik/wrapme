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

- (BOOL)cachedRecords:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (void)records:(WLSetBlock)success failure:(WLFailureBlock)failure;

- (void)beginCaching;

- (void)endCaching;

- (void)updateCachedRecords;

- (void)updateCachedRecordsAfterFailure;

- (void)contacts:(WLSetBlock)success failure:(WLFailureBlock)failure;

@end