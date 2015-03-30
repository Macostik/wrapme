//
//  WLAddressBook.h
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLAddressBookRecord.h"
#import "WLAddressBookPhoneNumber.h"

@class WLAddressBook;

@protocol WLAddressBookReceiver <NSObject>

@optional
- (void)addressBook:(WLAddressBook*)addressBook didUpdateCachedRecords:(NSArray*)cachedRecords;

@end


@interface WLAddressBook : WLBroadcaster

+ (instancetype)addressBook;

- (BOOL)cachedRecords:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (void)records:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (void)beginCaching;

- (void)endCaching;

- (void)updateCachedRecords;

- (void)updateCachedRecordsAfterFailure;

/**
 *  Get the list of records from Address Book.
 *  If record doesn't have at least one specified phone number it will be ignored.
 *
 *  @param success block for successful completion
 *  @param failure block for failed completion
 */
- (void)contacts:(WLArrayBlock)success failure:(WLFailureBlock)failure;

@end