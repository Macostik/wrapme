//
//  WLAddressBook.h
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLBlocks.h"

@interface WLAddressBook : NSObject

/**
 *  Get the list of records from Address Book.
 *  If record doesn't have at least one specified phone number it will be ignored.
 *
 *  @param success block for successful completion
 *  @param failure block for failed completion
 */
+ (void)contacts:(WLArrayBlock)success failure:(WLFailureBlock)failure;

@end

@interface WLContact : NSObject

@property (strong, nonatomic) NSString* name;

@property (strong, nonatomic) NSArray* users;

@property (nonatomic, readonly) BOOL signedUp;

@end

@interface NSString (WLAddressBook)

@property (nonatomic, strong) NSString* label;

@end