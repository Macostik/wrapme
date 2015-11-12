//
//  WLAddressBookPhoneNumber.h
//  meWrap
//
//  Created by Oleg Vishnivetskiy on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLAddressBookRecord;

@interface WLAddressBookPhoneNumber : NSObject

@property (weak, nonatomic) WLAddressBookRecord* record;

@property (strong, nonatomic) NSString *phone;

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) NSString *label;

@property (weak, nonatomic) User *user;

@property (strong, nonatomic) Asset *picture;

@property (nonatomic) BOOL activated;

- (BOOL)isEqualToPhoneNumber:(WLAddressBookPhoneNumber*)person;

@end
