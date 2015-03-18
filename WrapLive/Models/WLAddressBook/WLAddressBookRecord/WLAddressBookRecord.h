//
//  WLAddressBookRecord.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/26/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface WLAddressBookRecord : NSObject

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) NSArray *phoneNumbers;

@property (nonatomic, readonly) BOOL registered;

@property (readonly, nonatomic) NSString* priorityName;

@property (readonly, nonatomic) WLPicture* priorityPicture;

+ (void)record:(ABRecordRef)record completion:(WLContactBlock)completion;

+ (instancetype)record:(NSArray*)phoneNumbers;

@end

@interface NSString (WLAddressBook)

@property (nonatomic, strong) NSString *label;

@end
